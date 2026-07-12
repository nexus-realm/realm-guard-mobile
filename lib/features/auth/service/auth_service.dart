import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../src/rust/api/opaque.dart';
import '../data/auth_exception.dart';
import '../data/server_config.dart';
import 'opaque_client.dart';
import 'session_store.dart';

/// Orchestration de l'authentification **OPAQUE** : combine le client OPAQUE
/// (FFI), les appels HTTP au serveur et le stockage de session.
///
/// Le serveur n'apprend jamais le mot de passe : le client produit les messages
/// OPAQUE (FFI) et ne transmet que ceux-ci. Les échecs sont remontés en
/// [AuthException] (message utilisateur).
class AuthService {
  final OpaqueClient _opaque;
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;

  AuthService({
    required OpaqueClient opaque,
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
  }) : _opaque = opaque,
       _http = httpClient,
       _session = session,
       _config = config;

  /// Crée un compte. Le mot de passe ne quitte jamais l'appareil en clair.
  Future<void> register(String username, String password) async {
    final start = await _opaque.registerStart(password);
    final startResp = await _post('/auth/register/start', {
      'username': username,
      'request': base64.encode(start.message),
    });
    if (startResp.statusCode == 409) throw const AuthException.usernameTaken();
    if (startResp.statusCode != 200) throw const AuthException.server();

    final response = base64.decode(_json(startResp)['response'] as String);
    final finish = await _opaque.registerFinish(start.state, password, response);
    final finishResp = await _post('/auth/register/finish', {
      'username': username,
      'upload': base64.encode(finish.upload),
    });
    if (finishResp.statusCode == 409) throw const AuthException.usernameTaken();
    if (finishResp.statusCode != 201) throw const AuthException.server();
  }

  /// Se connecte. Lève [AuthException.invalidCredentials] si le mot de passe est
  /// faux (l'échec est détecté **côté client**). Stocke le token en cas de succès.
  Future<void> login(String username, String password) async {
    final start = await _opaque.loginStart(password);
    final startResp = await _post('/auth/login/start', {
      'username': username,
      'request': base64.encode(start.message),
    });
    if (startResp.statusCode != 200) throw const AuthException.server();

    final startBody = _json(startResp);
    final response = base64.decode(startBody['response'] as String);
    final flowId = startBody['flow_id'] as String;

    final finish = await _finishLogin(start.state, password, response);
    final finishResp = await _post('/auth/login/finish', {
      'flow_id': flowId,
      'finalization': base64.encode(finish.finalization),
    });
    if (finishResp.statusCode == 401) {
      throw const AuthException.invalidCredentials();
    }
    if (finishResp.statusCode != 200) throw const AuthException.server();

    await _session.write(_json(finishResp)['session_token'] as String);
  }

  /// Un token de session est-il stocké localement ?
  Future<bool> isLoggedIn() async => (await _session.read()) != null;

  /// Efface la session locale.
  Future<void> logout() => _session.clear();

  Future<OpaqueLoginFinish> _finishLogin(
    Uint8List state,
    String password,
    Uint8List response,
  ) async {
    try {
      return await _opaque.loginFinish(state, password, response);
    } catch (_) {
      // Le client ne peut pas déchiffrer l'enveloppe → mot de passe faux ou
      // utilisateur inconnu (réponse fabriquée par le serveur).
      throw const AuthException.invalidCredentials();
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await _http.post(
        Uri.parse('${_config.baseUrl}$path'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Exception {
      throw const AuthException.network();
    }
  }

  Map<String, dynamic> _json(http.Response resp) =>
      jsonDecode(resp.body) as Map<String, dynamic>;
}
