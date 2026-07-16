import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:realmguard/features/auth/data/auth_exception.dart';
import 'package:realmguard/features/auth/data/server_config.dart';
import 'package:realmguard/features/auth/service/auth_service.dart';
import 'package:realmguard/features/auth/service/opaque_client.dart';
import 'package:realmguard/features/auth/service/session_store.dart';
import 'package:realmguard/features/auth/service/vault_key_cipher.dart';
import 'package:realmguard/src/rust/api/opaque.dart';

/// Client OPAQUE inerte : jamais appelé (register/login sont neutralisés dans
/// [FakeAuthService]) — lève si on l'invoque par erreur.
class _UnusedOpaque implements OpaqueClient {
  @override
  Future<OpaqueClientStart> registerStart(String password) =>
      throw UnimplementedError();

  @override
  Future<OpaqueRegisterFinish> registerFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) => throw UnimplementedError();

  @override
  Future<OpaqueClientStart> loginStart(String password) =>
      throw UnimplementedError();

  @override
  Future<OpaqueLoginFinish> loginFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) => throw UnimplementedError();
}

/// Chiffreur de VaultKey inerte (jamais appelé par l'onboarding).
class _UnusedVaultKeyCipher implements VaultKeyCipher {
  @override
  Uint8List seal(Uint8List exportKey, Uint8List wrappedVaultKey) =>
      throw UnimplementedError();

  @override
  Uint8List open(Uint8List exportKey, Uint8List sealed) =>
      throw UnimplementedError();
}

/// Stockage de session en mémoire.
class _InMemorySession implements SessionStore {
  String? _token;

  @override
  Future<void> clear() async => _token = null;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;
}

/// Faux [AuthService] pour les tests : neutralise `register` / `login` (aucun FFI,
/// aucun réseau). Positionner [failure] pour simuler un échec (ex.
/// `AuthException.usernameTaken()`).
class FakeAuthService extends AuthService {
  FakeAuthService()
    : super(
        opaque: _UnusedOpaque(),
        vaultKey: _UnusedVaultKeyCipher(),
        httpClient: http.Client(),
        session: _InMemorySession(),
        config: const ServerConfig(baseUrl: 'http://test.local'),
      );

  /// Si non nul, [register] lève cette exception.
  AuthException? failure;
  final List<String> registeredUsernames = [];
  final List<String> loggedInUsernames = [];

  /// État de session simulé (pilote [isLoggedIn]).
  bool loggedIn = false;

  /// Le serveur détient-il déjà un backup de VaultKey ? (pilote
  /// [hasVaultKeyBackup]).
  bool hasBackup = false;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<bool> hasVaultKeyBackup() async => hasBackup;

  @override
  Future<void> logout() async => loggedIn = false;

  @override
  Future<void> register(String username, String password) async {
    final pendingFailure = failure;
    if (pendingFailure != null) throw pendingFailure;
    registeredUsernames.add(username);
  }

  /// Clé exportée factice renvoyée par [login] (sert au backup de la VaultKey).
  final exportKey = Uint8List.fromList(List<int>.filled(32, 6));

  @override
  Future<Uint8List> login(String username, String password) async {
    loggedInUsernames.add(username);
    loggedIn = true;
    return exportKey;
  }
}
