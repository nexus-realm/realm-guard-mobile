import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_key_provider.dart';

class EncryptionKeyProviderImpl extends EncryptionKeyProvider {
  final FlutterSecureStorage _storage;

  // The key used to look up the value inside Secure Storage
  static const String _storageKeyAlias = 'realm_guard_encryption_key_v1';

  EncryptionKeyProviderImpl(this._storage);

  @override
  Future<String> getEncryptionKey() async {
    final String? storedKey = await _storage.read(key: _storageKeyAlias);

    if (storedKey != null) {
      return storedKey;
    }

    final String newKey = _generateCryptographicallySecureKey();

    await _storage.write(key: _storageKeyAlias, value: newKey);

    return newKey;
  }

  /// Generates a random 32-byte (256-bit) key using the OS's secure random
  /// number generator.
  String _generateCryptographicallySecureKey() {
    final Random random = Random.secure();
    final Uint8List values = Uint8List.fromList(
      List.generate(32, (i) => random.nextInt(256)),
    );
    return base64Url.encode(values);
  }
}
