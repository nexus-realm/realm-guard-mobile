import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'base32.dart';

/// Algorithme HMAC supporté pour un TOTP.
enum TotpAlgorithm { sha1, sha256, sha512 }

TotpAlgorithm totpAlgorithmFromName(String name) {
  switch (name.toUpperCase()) {
    case 'SHA256':
      return TotpAlgorithm.sha256;
    case 'SHA512':
      return TotpAlgorithm.sha512;
    default:
      return TotpAlgorithm.sha1;
  }
}

String totpAlgorithmName(TotpAlgorithm algo) => switch (algo) {
  TotpAlgorithm.sha1 => 'SHA1',
  TotpAlgorithm.sha256 => 'SHA256',
  TotpAlgorithm.sha512 => 'SHA512',
};

/// Génère des codes TOTP (RFC 6238) localement, sans dépendance réseau.
abstract final class TotpGenerator {
  /// Génère le code pour [secretBase32] à l'instant [now] (défaut : maintenant).
  ///
  /// Lève [FormatException] si le secret n'est pas un Base32 valide.
  static Future<String> generate({
    required String secretBase32,
    int digits = 6,
    int period = 30,
    TotpAlgorithm algorithm = TotpAlgorithm.sha1,
    DateTime? now,
  }) async {
    final key = Base32.decode(secretBase32);
    if (key.isEmpty) {
      throw const FormatException('Secret TOTP vide ou invalide.');
    }

    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final counter = seconds ~/ period;
    return _hotp(key: key, counter: counter, digits: digits, algorithm: algorithm);
  }

  /// Secondes restantes avant l'expiration du code courant.
  static int remainingSeconds({int period = 30, DateTime? now}) {
    final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return period - (seconds % period);
  }

  /// Fraction de la période déjà écoulée (0..1), pour un anneau de progression.
  static double progress({int period = 30, DateTime? now}) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final periodMs = period * 1000;
    return (ms % periodMs) / periodMs;
  }

  static Future<String> _hotp({
    required Uint8List key,
    required int counter,
    required int digits,
    required TotpAlgorithm algorithm,
  }) async {
    // Compteur sur 8 octets big-endian.
    final message = Uint8List(8);
    var value = counter;
    for (var i = 7; i >= 0; i--) {
      message[i] = value & 0xFF;
      value >>= 8;
    }

    final mac = await _macAlgorithm(algorithm).calculateMac(
      message,
      secretKey: SecretKey(key),
    );
    final hash = mac.bytes;

    // Troncature dynamique (RFC 4226).
    final offset = hash[hash.length - 1] & 0x0F;
    final binary =
        ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    final otp = binary % _pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  static MacAlgorithm _macAlgorithm(TotpAlgorithm algorithm) => switch (algorithm) {
    TotpAlgorithm.sha1 => Hmac.sha1(),
    TotpAlgorithm.sha256 => Hmac.sha256(),
    TotpAlgorithm.sha512 => Hmac(Sha512()),
  };

  static int _pow10(int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
