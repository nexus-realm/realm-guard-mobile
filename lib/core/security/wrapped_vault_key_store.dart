import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage de la VaultKey **enrobée par la KEK** (abstrait pour la testabilité).
///
/// Le blob est déjà chiffré (AEAD sous la KEK) ; le secure storage ajoute une
/// couche. Sa présence sert aussi de marqueur « coffre migré vers le modèle
/// VaultKey » (cf. [VaultMigrator]).
abstract interface class WrappedVaultKeyStore {
  Future<Uint8List?> read();
  Future<void> write(List<int> wrapped);
  Future<void> clear();
}

/// Implémentation adossée au keystore de l'OS via `flutter_secure_storage`.
class SecureWrappedVaultKeyStore implements WrappedVaultKeyStore {
  const SecureWrappedVaultKeyStore(this._storage);

  static const _key = 'wrapped_vault_key_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List?> read() async {
    final stored = await _storage.read(key: _key);
    return stored == null ? null : base64Decode(stored);
  }

  @override
  Future<void> write(List<int> wrapped) =>
      _storage.write(key: _key, value: base64Encode(wrapped));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
