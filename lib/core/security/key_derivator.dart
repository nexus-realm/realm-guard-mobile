import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

abstract class KeyDerivator {
  KeyDerivator._();

  static const int _iterations = 3;
  static const int _memory = 65536; // in KB
  static const int _parallelism = 1;
  static const int _hashLength = 32; // 32 bytes = 256 bits

  /// Transforms the User's Password (e.g. "Monkey123") into a
  /// cryptographically secure 32-byte key using Argon2id.
  /// Throws [ArgumentError] if the password is empty or blank.
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

    final Argon2id algorithm = Argon2id(
      iterations: _iterations,
      memory: _memory,
      parallelism: _parallelism,
      hashLength: _hashLength,
    );

    return await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }
}
