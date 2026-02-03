import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';

class KeyDerivator {
  static final int _iterations = 32;
  static final int _memory = 65536; // in KB
  static final int _parallelism = 2;
  static final int _keyLength = 32; // 32 bytes = 256 bits

  /// Transforms the User's Password (e.g. "Monkey123") into a
  /// cryptographically secure 32-byte key.
  Future<SecretKey> deriveKeyFromPassword(
    String password,
    Uint8List salt,
  ) async {
    final result = await argon2.hashPasswordBytes(
      utf8.encode(password),
      salt: Salt(salt),
      iterations: _iterations,
      memory: _memory,
      parallelism: _parallelism,
      length: _keyLength,
      type: Argon2Type.id,
    );

    return SecretKey(result.encodedBytes);
  }
}
