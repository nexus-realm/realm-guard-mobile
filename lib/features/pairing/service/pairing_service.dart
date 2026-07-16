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
/// et la réception de la réponse.
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

/// Résultat d'un pairing réussi côté nouvel appareil.
class PairingReceipt {
  /// VaultKey reçue (clé racine du coffre).
  final Uint8List vaultKey;

  /// Compte rejoint (UUID textuel), extrait du blob scellé.
  final String accountId;

  /// SAS à afficher / comparer avec l'appareil source.
  final String sas;

  const PairingReceipt({
    required this.vaultKey,
    required this.accountId,
    required this.sas,
  });
}

/// Résultat du scellage côté **source** : SAS à faire confirmer, puis clé d'identité
/// du nouvel appareil à inscrire au registre.
class PairingSealOutcome {
  /// SAS à comparer avec le nouvel appareil.
  final String sas;

  /// Clé d'identité du nouvel appareil, **liée au transcript** (extraite du QR).
  /// À n'inscrire qu'**après** confirmation du SAS par l'utilisateur : sur un QR
  /// substitué, ce serait la clé de l'attaquant.
  final Uint8List devicePublicKey;

  const PairingSealOutcome({required this.sas, required this.devicePublicKey});
}

/// Contrat du service de pairing (abstrait pour la testabilité des ViewModels).
abstract interface class PairingApi {
  /// Nouvel appareil : démarre le pairing (QR + session). Crée l'identité d'appareil
  /// au premier appel et la réutilise ensuite.
  Future<PairingSession> startNewDevice();

  /// Nouvel appareil : attend puis ouvre la réponse → VaultKey + compte + SAS.
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout,
    Duration interval,
  });

  /// Appareil source : scanne, scelle, dépose → SAS + clé de l'appareil à inscrire.
  Future<PairingSealOutcome> pairScannedDevice({
    required String qrPayload,
    required String accountId,
    required Uint8List vaultKey,
  });

  /// Appareil source : inscrit l'appareil au registre du compte. **À n'appeler
  /// qu'après confirmation du SAS.**
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  });

  /// Nouvel appareil : prouve son identité (challenge-response Ed25519) et ouvre une
  /// session sur le compte.
  Future<void> authenticateDevice();
}

/// Orchestration du **pairing d'appareil** : combine le FFI cœur (X25519 + scellage,
/// clés d'identité Ed25519) et le serveur (relais `/pairing/{id}`, registre
/// `/devices`, auth `/auth/device/*`).
///
/// Le `relay_id` est une **enveloppe transport** (JSON `{i, q}` dans le QR) : le
/// serveur ne voit qu'un blob opaque, scellé vers la clé éphémère du nouvel appareil.
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

  /// **Nouvel appareil** — démarre le pairing : renvoie le QR à afficher + la session
  /// à conserver jusqu'à la réception. Le QR porte la clé d'identité de cet appareil.
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

  /// **Nouvel appareil** — attend (poll) la réponse déposée par la source puis
  /// l'ouvre. Renvoie la VaultKey, le compte rejoint et le SAS à comparer.
  @override
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final response = await _pollForResponse(session.relayId, timeout, interval);
    final PairingOpened opened;
    try {
      opened = _ffi.open(session.state, response);
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
    return PairingReceipt(
      vaultKey: opened.vaultKey,
      accountId: accountId,
      sas: opened.sas,
    );
  }

  /// **Appareil source** — scanne le QR, scelle `{accountId, vaultKey}` et dépose la
  /// réponse. Renvoie le SAS à faire confirmer + la clé d'identité du nouvel appareil.
  /// Nécessite une session active.
  @override
  Future<PairingSealOutcome> pairScannedDevice({
    required String qrPayload,
    required String accountId,
    required Uint8List vaultKey,
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

    final Uint8List accountBytes;
    try {
      accountBytes = AccountId.toBytes(accountId);
    } on FormatException {
      throw const PairingException.server();
    }

    final PairingSealed sealed;
    try {
      sealed = _ffi.seal(qr, accountBytes, vaultKey);
    } catch (_) {
      throw const PairingException.invalidQr();
    }

    final resp = await _post('/pairing/$relayId', token, {
      'response': base64.encode(sealed.response),
    });
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 204) throw const PairingException.server();
    return PairingSealOutcome(
      sas: sealed.sas,
      devicePublicKey: sealed.devicePublicKey,
    );
  }

  /// **Appareil source** — inscrit la clé de l'appareil au registre du compte.
  ///
  /// **À n'appeler qu'après confirmation du SAS** : la clé vient du QR scanné, donc
  /// un QR substitué (MITM) ferait inscrire l'appareil de l'attaquant.
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

  /// **Nouvel appareil** — challenge-response Ed25519 : demande un défi, le signe avec
  /// la graine locale, et échange la signature contre un token de session.
  ///
  /// Lève [PairingException.deviceRejected] si le serveur refuse (appareil non
  /// inscrit ou révoqué).
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

  Future<Uint8List> _pollForResponse(
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
