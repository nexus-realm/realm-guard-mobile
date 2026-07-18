import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../auth/data/server_config.dart';
import '../../auth/service/session_store.dart';
import '../data/sync_exception.dart';
import '../data/sync_models.dart';

/// Client du log de synchronisation (`/sync/*`), **gated par session**. Le
/// serveur est un log opaque : il ne déchiffre ni ne fusionne rien. Abstrait
/// pour la testabilité de l'orchestrateur.
abstract interface class SyncApi {
  /// Pousse un delta au log du compte. Renvoie son `seq` attribué.
  Future<int> pushDelta(Uint8List delta);

  /// Tire les deltas postérieurs à [since] (curseur). Lève
  /// [SyncException] `cursorGone` (410) si [since] précède le snapshot.
  Future<DeltaPage> pullDeltas({required int since, int? limit});

  /// Publie un snapshot couvrant [coversSeq] et compacte le log. Renvoie le
  /// nombre de deltas purgés.
  Future<int> putSnapshot(Uint8List snapshot, {required int coversSeq});

  /// Récupère le snapshot du compte, ou `null` s'il n'y en a pas encore.
  Future<RemoteSnapshot?> getSnapshot();
}

/// Implémentation HTTP, calquée sur `DevicesService` : `Bearer` depuis le
/// [SessionStore], ré-auth par clé d'appareil à la volée si la session manque.
class SyncService implements SyncApi {
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;
  final Future<void> Function() _ensureSession;

  SyncService({
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
    required Future<void> Function() ensureSession,
  }) : _http = httpClient,
       _session = session,
       _config = config,
       _ensureSession = ensureSession;

  @override
  Future<int> pushDelta(Uint8List delta) async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.post(
        _uri('/sync/deltas'),
        headers: {..._auth(token), 'content-type': 'application/json'},
        body: jsonEncode({'payload': base64.encode(delta)}),
      ),
    );
    if (resp.statusCode == 401) throw const SyncException.sessionExpired();
    if (resp.statusCode != 201) throw const SyncException.server();
    return (jsonDecode(resp.body) as Map<String, dynamic>)['seq'] as int;
  }

  @override
  Future<DeltaPage> pullDeltas({required int since, int? limit}) async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.get(
        _uri('/sync/deltas', {
          'since': '$since',
          if (limit != null) 'limit': '$limit',
        }),
        headers: _auth(token),
      ),
    );
    if (resp.statusCode == 401) throw const SyncException.sessionExpired();
    if (resp.statusCode == 410) throw const SyncException.cursorGone();
    if (resp.statusCode != 200) throw const SyncException.server();

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final deltas = (body['deltas'] as List<dynamic>)
        .map((entry) {
          final row = entry as Map<String, dynamic>;
          return RemoteDelta(
            seq: row['seq'] as int,
            payload: base64.decode(row['payload'] as String),
          );
        })
        .toList(growable: false);
    return DeltaPage(deltas: deltas, latest: body['latest'] as int);
  }

  @override
  Future<int> putSnapshot(Uint8List snapshot, {required int coversSeq}) async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.put(
        _uri('/sync/snapshot'),
        headers: {..._auth(token), 'content-type': 'application/json'},
        body: jsonEncode({
          'payload': base64.encode(snapshot),
          'covers_seq': coversSeq,
        }),
      ),
    );
    if (resp.statusCode == 401) throw const SyncException.sessionExpired();
    if (resp.statusCode != 200) throw const SyncException.server();
    return (jsonDecode(resp.body) as Map<String, dynamic>)['purged'] as int;
  }

  @override
  Future<RemoteSnapshot?> getSnapshot() async {
    final token = await _tokenOrAuthenticate();
    final resp = await _send(
      () => _http.get(_uri('/sync/snapshot'), headers: _auth(token)),
    );
    if (resp.statusCode == 404) return null;
    if (resp.statusCode == 401) throw const SyncException.sessionExpired();
    if (resp.statusCode != 200) throw const SyncException.server();

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return RemoteSnapshot(
      payload: base64.decode(body['payload'] as String),
      coversSeq: body['covers_seq'] as int,
    );
  }

  /// Token de session, en tentant une auth par clé d'appareil si absent.
  Future<String> _tokenOrAuthenticate() async {
    final existing = await _session.read();
    if (existing != null) return existing;
    try {
      await _ensureSession();
    } catch (_) {
      throw const SyncException.sessionExpired();
    }
    final token = await _session.read();
    if (token == null) throw const SyncException.sessionExpired();
    return token;
  }

  Map<String, String> _auth(String token) => {'authorization': 'Bearer $token'};

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on Exception {
      throw const SyncException.network();
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${_config.baseUrl}$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }
}
