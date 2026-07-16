import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../src/rust/api/pairing.dart';
import '../../auth/data/account_id.dart';
import '../../auth/data/server_config.dart';
import '../../auth/service/session_store.dart';
import '../data/pairing_exception.dart';
import 'device_key_ffi.dart';
import 'device_key_store.dart';
import 'pairing_ffi.dart';

/// Session de pairing côté **nouvel appareil** : à conserver entre l'affichage du QR
/// et la réception.
class PairingSession {
  /// État éphémère du cœur (contient le secret X25519).
  final Uint8List state;

  /// Clé de routage du relais (enveloppe transport, hors cœur).
  final String relayId;

  /// Contenu à encoder dans le QR affiché.
  final String qrPayload;

  const PairingSession({
    required this.state,
    required this.relayId,
    required this.qrPayload,
  });
}

/// **Tour 1 terminé côté nouvel appareil** : le SAS peut être comparé. La VaultKey
/// n'arrivera qu'après confirmation côté source.
class PairingHandshake {
  /// État de session (contient la clé AEAD dérivée) — sensible, éphémère.
  final Uint8List state;

  /// SAS à afficher / comparer.
  final String sas;

  const PairingHandshake({required this.state, required this.sas});
}

/// **Tour 1 terminé côté source** : SAS à faire confirmer avant tout envoi.
class PairingSourceHandshake {
  /// État de session (contient la clé AEAD dérivée) — sensible, éphémère.
  final Uint8List state;

  /// Routage du relais, pour le dépôt du tour 2.
  final String relayId;

  /// SAS à comparer avec le nouvel appareil.
  final String sas;

  /// Clé d'identité du nouvel appareil, **liée au transcript** (extraite du QR). À
  /// n'inscrire qu'après confirmation du SAS.
  final Uint8List devicePublicKey;

  const PairingSourceHandshake({
    required this.state,
    required this.relayId,
    required this.sas,
    required this.devicePublicKey,
  });
}

/// Résultat d'un pairing réussi côté nouvel appareil (tour 2).
class PairingReceipt {
  /// VaultKey reçue (clé racine du coffre).
  final Uint8List vaultKey;

  /// Compte rejoint (UUID textuel), extrait du blob scellé.
  final String accountId;

  const PairingReceipt({required this.vaultKey, required this.accountId});
}

/// Contrat du service de pairing (abstrait pour la testabilité des ViewModels).
abstract interface class PairingApi {
  /// Nouvel appareil : démarre le pairing (QR + session). Crée l'identité d'appareil
  /// au premier appel et la réutilise ensuite.
  Future<PairingSession> startNewDevice();

  /// **Tour 1, nouvel appareil** : attend la clé publique de la source et dérive le
  /// SAS à comparer. Rien de sensible n'a encore circulé.
  Future<PairingHandshake> awaitSourceHello(
    PairingSession session, {
    Duration timeout,
    Duration interval,
  });

  /// **Tour 2, nouvel appareil** : attend la VaultKey scellée — elle n'arrive que si
  /// l'utilisateur a confirmé le SAS côté source.
  Future<PairingReceipt> awaitVaultKey(
    PairingSession session,
    PairingHandshake handshake, {
    Duration timeout,
    Duration interval,
  });

  /// **Tour 1, source** : scanne le QR, dérive le SAS et dépose sa clé publique.
  Future<PairingSourceHandshake> beginPairing({required String qrPayload});

  /// **Tour 2, source** : scelle la VaultKey et la dépose. **À n'appeler qu'après
  /// confirmation du SAS** — c'est ce qui empêche un MITM de l'obtenir.
  Future<void> sealVaultKey({
    required PairingSourceHandshake handshake,
    required String accountId,
    required Uint8List vaultKey,
  });

  /// Source : inscrit l'appareil au registre du compte. **Après confirmation du SAS.**
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  });

  /// Nouvel appareil : prouve son identité (challenge-response Ed25519) et ouvre une
  /// session sur le compte.
  Future<void> authenticateDevice();
}

/// Orchestration du **pairing d'appareil en deux tours** : combine le FFI cœur
/// (X25519, SAS, scellage, clés Ed25519) et le serveur (relais `/pairing/{id}`,
/// registre `/devices`, auth `/auth/device/*`).
///
/// Le relais est une **boîte aux lettres à usage unique** (`GETDEL`) : on l'utilise
/// **deux fois de suite** sur le même `relay_id` — d'abord le `hello` (tour 1), puis
/// le blob scellé (tour 2). Le serveur ne voit que des octets opaques.
class PairingService implements PairingApi {
  final PairingFfi _ffi;
  final DeviceKeyFfi _deviceKeyFfi;
  final DeviceKeyStore _deviceKeyStore;
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;

  PairingService({
    required PairingFfi ffi,
    required DeviceKeyFfi deviceKeyFfi,
    required DeviceKeyStore deviceKeyStore,
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
  }) : _ffi = ffi,
       _deviceKeyFfi = deviceKeyFfi,
       _deviceKeyStore = deviceKeyStore,
       _http = httpClient,
       _session = session,
       _config = config;

  @override
  Future<PairingSession> startNewDevice() async {
    final deviceKey = await _ensureDeviceKey();
    final start = _ffi.start(deviceKey.public);
    final relayId = _randomRelayId();
    final qrPayload = jsonEncode({'i': relayId, 'q': base64.encode(start.qr)});
    return PairingSession(
      state: start.state,
      relayId: relayId,
      qrPayload: qrPayload,
    );
  }

  @override
  Future<PairingHandshake> awaitSourceHello(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final hello = await _pollRelay(session.relayId, timeout, interval);
    final PairingConfirm confirmed;
    try {
      confirmed = _ffi.confirm(session.state, hello);
    } catch (_) {
      throw const PairingException.corrupted();
    }
    return PairingHandshake(state: confirmed.state, sas: confirmed.sas);
  }

  @override
  Future<PairingReceipt> awaitVaultKey(
    PairingSession session,
    PairingHandshake handshake, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final sealed = await _pollRelay(session.relayId, timeout, interval);
    final PairingOpened opened;
    try {
      opened = _ffi.open(handshake.state, sealed);
    } catch (_) {
      // Le blob ne s'ouvre pas → mauvais destinataire ou altération.
      throw const PairingException.corrupted();
    }
    final String accountId;
    try {
      accountId = AccountId.fromBytes(opened.accountId);
    } on FormatException {
      throw const PairingException.corrupted();
    }
    return PairingReceipt(vaultKey: opened.vaultKey, accountId: accountId);
  }

  @override
  Future<PairingSourceHandshake> beginPairing({
    required String qrPayload,
  }) async {
    final token = await _requireToken();

    final String relayId;
    final Uint8List qr;
    try {
      final envelope = jsonDecode(qrPayload) as Map<String, dynamic>;
      relayId = envelope['i'] as String;
      qr = base64.decode(envelope['q'] as String);
    } catch (_) {
      throw const PairingException.invalidQr();
    }

    final PairingSourceBegin begin;
    try {
      begin = _ffi.begin(qr);
    } catch (_) {
      throw const PairingException.invalidQr();
    }

    // Tour 1 : on ne dépose que la clé publique — rien à voler ici.
    final resp = await _post('/pairing/$relayId', token, {
      'response': base64.encode(begin.hello),
    });
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 204) throw const PairingException.server();

    return PairingSourceHandshake(
      state: begin.state,
      relayId: relayId,
      sas: begin.sas,
      devicePublicKey: begin.devicePublicKey,
    );
  }

  @override
  Future<void> sealVaultKey({
    required PairingSourceHandshake handshake,
    required String accountId,
    required Uint8List vaultKey,
  }) async {
    final token = await _requireToken();

    final Uint8List accountBytes;
    try {
      accountBytes = AccountId.toBytes(accountId);
    } on FormatException {
      throw const PairingException.server();
    }

    final Uint8List sealed;
    try {
      sealed = _ffi.seal(handshake.state, accountBytes, vaultKey);
    } catch (_) {
      throw const PairingException.server();
    }

    final resp = await _post('/pairing/${handshake.relayId}', token, {
      'response': base64.encode(sealed),
    });
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 204) throw const PairingException.server();
  }

  @override
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  }) async {
    final token = await _requireToken();
    final resp = await _post('/devices', token, {
      'device_pk': base64.encode(devicePublicKey),
      'name': name,
    });
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 201) throw const PairingException.server();
  }

  @override
  Future<void> authenticateDevice() async {
    final deviceKey = await _deviceKeyStore.read();
    if (deviceKey == null) {
      throw StateError("Aucune identité d'appareil : pairing non effectué.");
    }

    final challengeResp = await _postPublic('/auth/device/challenge', {
      'device_pk': base64.encode(deviceKey.public),
    });
    if (challengeResp.statusCode != 200) throw const PairingException.server();
    final Uint8List nonce;
    try {
      final body = jsonDecode(challengeResp.body) as Map<String, dynamic>;
      nonce = base64.decode(body['challenge'] as String);
    } catch (_) {
      throw const PairingException.server();
    }

    final signature = _deviceKeyFfi.sign(deviceKey.secret, nonce);

    final verifyResp = await _postPublic('/auth/device/verify', {
      'device_pk': base64.encode(deviceKey.public),
      'signature': base64.encode(signature),
    });
    if (verifyResp.statusCode == 401) {
      throw const PairingException.deviceRejected();
    }
    if (verifyResp.statusCode != 200) throw const PairingException.server();
    try {
      final body = jsonDecode(verifyResp.body) as Map<String, dynamic>;
      await _session.write(body['session_token'] as String);
    } catch (_) {
      throw const PairingException.server();
    }
  }

  /// Identité d'appareil : réutilisée si déjà présente, sinon générée et persistée.
  /// Réutiliser la clé garde l'appareil reconnaissable après un ré-appairage.
  Future<StoredDeviceKey> _ensureDeviceKey() async {
    final existing = await _deviceKeyStore.read();
    if (existing != null) return existing;
    final generated = _deviceKeyFfi.generate();
    final key = StoredDeviceKey(
      public: generated.public,
      secret: generated.secret,
    );
    await _deviceKeyStore.write(key);
    return key;
  }

  /// Attend un dépôt sur le relais (usage unique). Sert aux **deux** tours.
  Future<Uint8List> _pollRelay(
    String relayId,
    Duration timeout,
    Duration interval,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final resp = await _get('/pairing/$relayId');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return base64.decode(body['response'] as String);
      }
      if (resp.statusCode != 404) throw const PairingException.server();
      await Future<void>.delayed(interval);
    }
    throw const PairingException.timeout();
  }

  /// 16 octets aléatoires en hexadécimal (charset base64url-safe accepté par le
  /// relais serveur).
  String _randomRelayId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<String> _requireToken() async {
    final token = await _session.read();
    if (token == null) throw const PairingException.sessionExpired();
    return token;
  }

  Future<http.Response> _post(
    String path,
    String token,
    Map<String, dynamic> body,
  ) => _send(
    () => _http.post(
      _uri(path),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ),
  );

  /// POST sans session : l'appareil n'est pas encore authentifié (`/auth/device/*`).
  Future<http.Response> _postPublic(String path, Map<String, dynamic> body) =>
      _send(
        () => _http.post(
          _uri(path),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  Future<http.Response> _get(String path) => _send(() => _http.get(_uri(path)));

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on Exception {
      throw const PairingException.network();
    }
  }

  Uri _uri(String path) => Uri.parse('${_config.baseUrl}$path');
}
