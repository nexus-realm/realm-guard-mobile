import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identité d'appareil persistée : graine secrète Ed25519 + clé publique.
///
/// La graine **ne quitte jamais l'appareil** : elle sert uniquement à signer les
/// défis d'authentification. Seule [public] voyage (QR, puis registre du compte).
class StoredDeviceKey {
  /// Clé publique (32 o) — inscrite au registre du compte.
  final Uint8List public;

  /// Graine secrète (32 o) — secret local.
  final Uint8List secret;

  const StoredDeviceKey({required this.public, required this.secret});
}

/// Persistance de l'identité d'appareil (abstrait pour la testabilité).
abstract interface class DeviceKeyStore {
  /// Identité de cet appareil, ou `null` s'il n'en a pas encore.
  Future<StoredDeviceKey?> read();

  Future<void> write(StoredDeviceKey key);

  Future<void> clear();
}

/// Implémentation adossée au keystore de l'OS via `flutter_secure_storage`.
class SecureDeviceKeyStore implements DeviceKeyStore {
  static const _secretKey = 'device_signing_key_v1';
  static const _publicKey = 'device_public_key_v1';

  final FlutterSecureStorage _storage;

  const SecureDeviceKeyStore(this._storage);

  @override
  Future<StoredDeviceKey?> read() async {
    final secret = await _storage.read(key: _secretKey);
    final public = await _storage.read(key: _publicKey);
    // Les deux vont de pair : une moitié seule est inutilisable.
    if (secret == null || public == null) return null;
    return StoredDeviceKey(
      public: base64.decode(public),
      secret: base64.decode(secret),
    );
  }

  @override
  Future<void> write(StoredDeviceKey key) async {
    await _storage.write(key: _secretKey, value: base64.encode(key.secret));
    await _storage.write(key: _publicKey, value: base64.encode(key.public));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _secretKey);
    await _storage.delete(key: _publicKey);
  }
}
