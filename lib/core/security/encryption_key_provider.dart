/// An abstract class that defines a contract for providing encryption keys.
abstract class EncryptionKeyProvider {
  /// Retrieves the encryption key used for securing sensitive data.
  ///
  /// Returns a [Future<String>] that completes with the encryption key.
  Future<String> getEncryptionKey();
}
