import 'package:flutter/services.dart';

/// Raised when the platform Keystore cannot be used (no secure lock screen, or
/// the Android API level is too low). The caller should fall back to the
/// master password.
class KeystoreUnavailableException implements Exception {
  const KeystoreUnavailableException([this.message]);

  final String? message;

  @override
  String toString() => 'KeystoreUnavailableException: ${message ?? ''}';
}

/// Raised when the user has not authenticated within the Keystore key's
/// validity window. The caller should re-prompt or fall back to the password.
class UserNotAuthenticatedException implements Exception {
  const UserNotAuthenticatedException();

  @override
  String toString() => 'UserNotAuthenticatedException';
}

/// Raised when the backing Keystore key has been permanently invalidated
/// (e.g. a new biometric was enrolled). The caller must drop the stored key
/// and require a fresh password unlock.
class KeyInvalidatedException implements Exception {
  const KeyInvalidatedException();

  @override
  String toString() => 'KeyInvalidatedException';
}

/// Thin Dart wrapper over the native Android Keystore method channel.
///
/// The native side keeps a hardware-backed RSA key pair protected by
/// `setUserAuthenticationRequired(true)` +
/// `setUserAuthenticationValidityDurationSeconds(...)`. The public key wraps
/// (encrypts) the derived vault key without authentication; the private key
/// unwraps it only after a recent device / biometric authentication.
///
/// The plaintext vault key therefore never reaches persistent storage: only
/// the ciphertext does, and it is useless without the hardware key.
class KeystoreKeyGuard {
  const KeystoreKeyGuard();

  static const MethodChannel _channel = MethodChannel(
    'io.github.sachabarbet.realm_guard_mobile/secure_keystore',
  );

  /// Whether an authentication-bound Keystore key can be used on this device
  /// (API 23+ and a secure lock screen configured).
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Encrypts [keyBytes] with the Keystore public key. Does not require
  /// authentication. Creates the key pair on first use.
  Future<Uint8List> wrap(List<int> keyBytes) async {
    final result = await _channel.invokeMethod<Uint8List>('wrap', <String, Object?>{
      'key': Uint8List.fromList(keyBytes),
    });
    if (result == null) {
      throw const KeystoreUnavailableException('wrap returned null');
    }
    return result;
  }

  /// Decrypts [blob] with the Keystore private key. Requires a recent
  /// authentication; throws [UserNotAuthenticatedException] or
  /// [KeyInvalidatedException] otherwise.
  Future<Uint8List> unwrap(Uint8List blob) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('unwrap', <String, Object?>{
        'blob': blob,
      });
      if (result == null) {
        throw const UserNotAuthenticatedException();
      }
      return result;
    } on PlatformException catch (error) {
      switch (error.code) {
        case 'user_not_authenticated':
          throw const UserNotAuthenticatedException();
        case 'key_invalidated':
          throw const KeyInvalidatedException();
        default:
          throw KeystoreUnavailableException(error.code);
      }
    }
  }

  /// Removes the backing Keystore key. Best-effort.
  Future<void> deleteKey() async {
    try {
      await _channel.invokeMethod<void>('deleteKey');
    } on PlatformException {
      // Best-effort: nothing to clean up if the platform call fails.
    } on MissingPluginException {
      // Best-effort: channel not registered (non-Android / tests).
    }
  }
}
