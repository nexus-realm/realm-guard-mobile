import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';

abstract class KeyDerivator {
  KeyDerivator._();

  static const int _iterations = 3;
  static const int _memory = 65536; // in KB
  static const int _parallelism = 2;
  static const int _keyLength = 32; // 32 bytes = 256 bits

  /// Transforms the User's Password (e.g. "Monkey123") into a
  /// cryptographically secure 32-byte key.
  static Future<SecretKey> deriveKeyFromPassword(
    String password,
    Uint8List salt,
  ) async {
    if (password.trim().isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password must not be empty or blank.',
      );
    }

    final result = await argon2.hashPasswordBytes(
      utf8.encode(password),
      salt: Salt(salt),
      iterations: _iterations,
      memory: _memory,
      parallelism: _parallelism,
      length: _keyLength,
      type: Argon2Type.id,
    );

    return SecretKey(result.rawBytes);
  }
}
