import 'dart:typed_data';

/// Conversion entre l'`account_id` **UUID textuel** (forme serveur, `/auth/me`) et sa
/// forme **16 octets** attendue par le cœur (blob de pairing).
abstract final class AccountId {
  /// UUID textuel → 16 octets.
  ///
  /// Lève [FormatException] si l'UUID est malformé.
  static Uint8List toBytes(String uuid) {
    final hex = uuid.replaceAll('-', '');
    if (hex.length != 32) {
      throw FormatException('account_id invalide (UUID attendu)', uuid);
    }
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      final byte = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      if (byte == null) {
        throw FormatException('account_id invalide (UUID attendu)', uuid);
      }
      bytes[i] = byte;
    }
    return bytes;
  }

  /// 16 octets → UUID textuel canonique (8-4-4-4-12).
  ///
  /// Lève [FormatException] si la longueur n'est pas 16.
  static String fromBytes(Uint8List bytes) {
    if (bytes.length != 16) {
      throw FormatException(
        'account_id invalide (16 octets attendus, reçu ${bytes.length})',
      );
    }
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
