import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../auth/data/server_config.dart';
import '../../auth/service/session_store.dart';
import '../data/pairing_exception.dart';
import 'device_key_store.dart';

/// Un appareil inscrit au registre du compte.
class PairedDevice {
  final String id;
  final String name;
  final DateTime createdAt;

  /// Accès coupé (révoqué) côté serveur.
  final bool revoked;

  /// **Cet** appareil : sa clé publique est celle stockée localement. Sert à éviter
  /// de se révoquer soi-même par mégarde.
  final bool isCurrent;

  const PairedDevice({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.revoked,
    required this.isCurrent,
  });
}

/// Contrat de gestion des appareils (abstrait pour la testabilité du ViewModel).
abstract interface class DevicesApi {
  /// Appareils du compte, « cet appareil » marqué.
  Future<List<PairedDevice>> list();

  Future<void> rename(String deviceId, String name);

  /// Coupe l'accès d'un appareil (le serveur refusera ses futures sessions).
  Future<void> revoke(String deviceId);
}

/// Gestion du registre d'appareils (`/devices`), gated par session.
///
/// Un appareil **appairé** n'a pas forcément de session au moment d'ouvrir l'écran
/// (la source ne l'inscrit qu'après confirmation du SAS, donc sa première tentative
/// d'auth échoue) : [ensureSession] est donc retentée à la volée avant l'appel.
class DevicesService implements DevicesApi {
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;
  final DeviceKeyStore _deviceKeyStore;
  final Future<void> Function() _ensureSession;

  DevicesService({
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
    required DeviceKeyStore deviceKeyStore,
    required Future<void> Function() ensureSession,
  }) : _http = httpClient,
       _session = session,
       _config = config,
       _deviceKeyStore = deviceKeyStore,
       _ensureSession = ensureSession;

  @override
  Future<List<PairedDevice>> list() async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.get(_uri('/devices'), headers: _auth(token)),
    );
    if (resp.statusCode == 401) throw const PairingException.sessionExpired();
    if (resp.statusCode != 200) throw const PairingException.server();

    final localKey = await _deviceKeyStore.read();
    final rows = jsonDecode(resp.body) as List<dynamic>;
    return rows
        .map((row) {
          final device = row as Map<String, dynamic>;
          final devicePk = base64.decode(device['device_pk'] as String);
          return PairedDevice(
            id: device['id'] as String,
            name: device['name'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (device['created_at'] as int) * 1000,
            ),
            revoked: device['revoked'] as bool,
            isCurrent: localKey != null && _sameKey(localKey.public, devicePk),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> rename(String deviceId, String name) async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.patch(
        _uri('/devices/$deviceId'),
        headers: {..._auth(token), 'content-type': 'application/json'},
        body: jsonEncode({'name': name}),
      ),
    );
    _expectNoContent(resp.statusCode);
  }

  @override
  Future<void> revoke(String deviceId) async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.delete(_uri('/devices/$deviceId'), headers: _auth(token)),
    );
    _expectNoContent(resp.statusCode);
  }

  void _expectNoContent(int status) {
    if (status == 401) throw const PairingException.sessionExpired();
    if (status == 404) throw const PairingException.deviceRejected();
    if (status != 204) throw const PairingException.server();
  }

  /// Token de session, en tentant une auth par clé d'appareil si absent.
  Future<String> _tokenOrAuthenticate() async {
    final existing = await _session.read();
    if (existing != null) return existing;
    try {
      await _ensureSession();
    } catch (_) {
      // Pas d'identité d'appareil, ou serveur qui refuse : on reste sans session.
      throw const PairingException.sessionExpired();
    }
    final token = await _session.read();
    if (token == null) throw const PairingException.sessionExpired();
    return token;
  }

  bool _sameKey(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, String> _auth(String token) => {'authorization': 'Bearer $token'};

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on Exception {
      throw const PairingException.network();
    }
  }

  Uri _uri(String path) => Uri.parse('${_config.baseUrl}$path');
}
