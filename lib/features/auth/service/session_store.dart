import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage du token de session (abstrait pour la testabilité).
abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Implémentation adossée au keystore de l'OS via `flutter_secure_storage`.
class SecureSessionStore implements SessionStore {
  static const _key = 'session_token_v1';

  final FlutterSecureStorage _storage;

  const SecureSessionStore(this._storage);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
