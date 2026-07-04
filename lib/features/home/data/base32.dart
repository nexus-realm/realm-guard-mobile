import 'dart:typed_data';

/// Décodage Base32 (RFC 4648), utilisé pour les secrets TOTP.
abstract final class Base32 {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Décode une chaîne Base32 en octets. Tolère les espaces, le padding `=` et
  /// la casse. Lève [FormatException] sur un caractère invalide.
  static Uint8List decode(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s=]'), '').toUpperCase();
    if (cleaned.isEmpty) return Uint8List(0);

    final output = <int>[];
    var buffer = 0;
    var bitsLeft = 0;

    for (final char in cleaned.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) {
        throw FormatException('Caractère Base32 invalide : $char');
      }
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        output.add((buffer >> bitsLeft) & 0xFF);
      }
    }
    return Uint8List.fromList(output);
  }

  /// Indique si [input] est un secret Base32 valide et non vide.
  static bool isValid(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s=]'), '');
    if (cleaned.isEmpty) return false;
    return RegExp(r'^[A-Za-z2-7]+$').hasMatch(cleaned);
  }
}
