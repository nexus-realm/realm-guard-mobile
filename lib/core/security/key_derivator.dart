import 'dart:isolate';
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
  ///
  /// The CPU- and memory-intensive Argon2id computation runs on a background
  /// isolate via [Isolate.run], so it never blocks the UI thread during unlock
  /// or onboarding. The derived key bytes (sendable) are returned from the
  /// isolate and re-wrapped into a [SecretKey] on the caller's isolate.
  ///
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

    final keyBytes = await Isolate.run(() => _deriveKeyBytes(password, salt));
    return SecretKey(keyBytes);
  }

  /// Runs on a background isolate: performs the Argon2id derivation and returns
  /// the raw 32-byte key.
  static Future<List<int>> _deriveKeyBytes(
    String password,
    Uint8List salt,
  ) async {
    final Argon2id algorithm = Argon2id(
      iterations: _iterations,
      memory: _memory,
      parallelism: _parallelism,
      hashLength: _hashLength,
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    return secretKey.extractBytes();
  }
}
