import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../src/rust/api/opaque.dart';
import '../data/auth_exception.dart';
import '../data/server_config.dart';
import '../data/stored_vault_key.dart';
import 'opaque_client.dart';
import 'session_store.dart';
import 'vault_key_cipher.dart';

/// Orchestration de l'authentification **OPAQUE** : combine le client OPAQUE
/// (FFI), les appels HTTP au serveur et le stockage de session.
///
/// Le serveur n'apprend jamais le mot de passe : le client produit les messages
/// OPAQUE (FFI) et ne transmet que ceux-ci. Les échecs sont remontés en
/// [AuthException] (message utilisateur).
class AuthService {
  final OpaqueClient _opaque;
  final VaultKeyCipher _vaultKey;
  final http.Client _http;
  final SessionStore _session;
  final ServerConfig _config;

  AuthService({
    required OpaqueClient opaque,
    required VaultKeyCipher vaultKey,
    required http.Client httpClient,
    required SessionStore session,
    required ServerConfig config,
  }) : _opaque = opaque,
       _vaultKey = vaultKey,
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
    final finish = await _opaque.registerFinish(
      start.state,
      password,
      response,
    );
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

  /// Identifiant (UUID) du compte de la session courante, via `/auth/me`.
  /// L'appareil **source** en a besoin pour sceller le blob de pairing (le nouvel
  /// appareil apprend ainsi quel compte il rejoint). Nécessite une session active.
  Future<String> currentAccountId() async {
    final token = await _requireToken();
    final resp = await _get('/auth/me', token);
    if (resp.statusCode == 401) throw const AuthException.sessionExpired();
    if (resp.statusCode != 200) throw const AuthException.server();
    return _json(resp)['account_id'] as String;
  }

  /// Téléverse la VaultKey pour la synchro multi-appareils. [wrappedVaultKey]
  /// (déjà enrobée par la KEK) est **ré-enrobée** sous la clé exportée OPAQUE
  /// ([exportKey], obtenue au register/login) avant l'envoi ; [salt] (non secret)
  /// est stocké tel quel. Nécessite une session active.
  Future<void> uploadVaultKey({
    required Uint8List exportKey,
    required Uint8List wrappedVaultKey,
    required Uint8List salt,
  }) async {
    final token = await _requireToken();
    final sealed = _vaultKey.seal(exportKey, wrappedVaultKey);
    final resp = await _put('/vault/key', token, {
      'wrapped_key': base64.encode(sealed),
      'salt': base64.encode(salt),
    });
    if (resp.statusCode == 401) throw const AuthException.sessionExpired();
    if (resp.statusCode != 204) throw const AuthException.server();
  }

  /// Récupère la VaultKey enrobée depuis le serveur et la **désenrobe** avec la clé
  /// exportée OPAQUE ([exportKey]). Renvoie `null` si aucune clé n'est stockée
  /// (appareil jamais synchronisé). Nécessite une session active. Lève
  /// [AuthException.corruptedVaultKey] si le blob est illisible (clé/altération).
  Future<StoredVaultKey?> fetchVaultKey(Uint8List exportKey) async {
    final token = await _requireToken();
    final resp = await _get('/vault/key', token);
    if (resp.statusCode == 404) return null;
    if (resp.statusCode == 401) throw const AuthException.sessionExpired();
    if (resp.statusCode != 200) throw const AuthException.server();

    final body = _json(resp);
    final sealed = base64.decode(body['wrapped_key'] as String);
    final salt = base64.decode(body['salt'] as String);
    final Uint8List wrappedVaultKey;
    try {
      wrappedVaultKey = _vaultKey.open(exportKey, sealed);
    } on Object {
      // Le blob ne se désenrobe pas → mauvaise clé exportée ou altération.
      throw const AuthException.corruptedVaultKey();
    }
    return StoredVaultKey(wrappedVaultKey: wrappedVaultKey, salt: salt);
  }

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

  Future<http.Response> _post(String path, Map<String, dynamic> body) => _send(
    () => _http.post(
      _uri(path),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  Future<http.Response> _put(
    String path,
    String token,
    Map<String, dynamic> body,
  ) => _send(
    () => _http.put(
      _uri(path),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ),
  );

  Future<http.Response> _get(String path, String token) => _send(
    () => _http.get(_uri(path), headers: {'authorization': 'Bearer $token'}),
  );

  /// Exécute un appel HTTP en convertissant toute panne réseau en [AuthException].
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on Exception {
      throw const AuthException.network();
    }
  }

  Uri _uri(String path) => Uri.parse('${_config.baseUrl}$path');

  /// Lit le token de session ; lève [AuthException.sessionExpired] si absent.
  Future<String> _requireToken() async {
    final token = await _session.read();
    if (token == null) throw const AuthException.sessionExpired();
    return token;
  }

  Map<String, dynamic> _json(http.Response resp) =>
      jsonDecode(resp.body) as Map<String, dynamic>;
}
