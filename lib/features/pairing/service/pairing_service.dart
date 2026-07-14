import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../src/rust/api/pairing.dart';
import '../../auth/data/server_config.dart';
import '../../auth/service/session_store.dart';
import '../data/pairing_exception.dart';
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

  /// SAS à afficher / comparer avec l'appareil source.
  final String sas;

  const PairingReceipt({required this.vaultKey, required this.sas});
}

/// Contrat du service de pairing (abstrait pour la testabilité des ViewModels).
abstract interface class PairingApi {
  /// Nouvel appareil : démarre le pairing (QR + session).
  PairingSession startNewDevice();

  /// Nouvel appareil : attend puis ouvre la réponse → VaultKey + SAS.
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout,
    Duration interval,
  });

  /// Appareil source : scanne, scelle, dépose → SAS.
  Future<String> pairScannedDevice({
    required String qrPayload,
    required Uint8List vaultKey,
  });
}

/// Orchestration du **pairing d'appareil** : combine le FFI cœur (X25519 + scellage)
/// et le relais serveur (`/pairing/{id}`).
///
/// Le `relay_id` est une **enveloppe transport** (JSON `{i, q}` dans le QR) : le
/// serveur ne voit qu'un blob opaque, scellé vers la clé éphémère du nouvel appareil.
class PairingService implements PairingApi {
  final PairingFfi _ffi;
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;

  PairingService({
    required PairingFfi ffi,
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
  }) : _ffi = ffi,
       _http = httpClient,
       _session = session,
       _config = config;

  /// **Nouvel appareil** — démarre le pairing : renvoie le QR à afficher + la session
  /// à conserver jusqu'à la réception.
  @override
  PairingSession startNewDevice() {
    final start = _ffi.start();
    final relayId = _randomRelayId();
    final qrPayload = jsonEncode({'i': relayId, 'q': base64.encode(start.qr)});
    return PairingSession(
      state: start.state,
      relayId: relayId,
      qrPayload: qrPayload,
    );
  }

  /// **Nouvel appareil** — attend (poll) la réponse déposée par la source puis
  /// l'ouvre. Renvoie la VaultKey + le SAS à comparer.
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
    return PairingReceipt(vaultKey: opened.vaultKey, sas: opened.sas);
  }

  /// **Appareil source** — scanne le QR, scelle la VaultKey et dépose la réponse.
  /// Renvoie le SAS à afficher (à comparer avec le nouvel appareil). Nécessite une
  /// session active.
  @override
  Future<String> pairScannedDevice({
    required String qrPayload,
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

    final PairingSealed sealed;
    try {
      sealed = _ffi.seal(qr, vaultKey);
    } catch (_) {
      throw const PairingException.invalidQr();
    }

    final resp = await _post('/pairing/$relayId', token, {
      'response': base64.encode(sealed.response),
    });
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 204) throw const PairingException.server();
    return sealed.sas;
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
