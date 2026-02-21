import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../exceptions/security_exception.dart';

abstract class SaltManager {
  SaltManager._();

  static const int _saltLength = 32;
  static const String _fileName = 'realmguard_security_metadata.salt';

  /// Retrieves the existing salt or generates a new one if it's a new install.
  /// Generated salt is stored on disk.
  /// Salt is not a secret but must be unique and persistent.
  static Future<Uint8List> getOrGenerateSalt() async {
    final file = await _getSaltFile();

    if (await file.exists()) {
      // 1. Existing user: Read the salt from disk
      final bytes = await file.readAsBytes();

      if (bytes.length != _saltLength) {
        throw const SecurityException("Corrupted salt file. Security risk.");
      }
      return bytes;
    } else {
      final newSalt = _generateRandomSalt();

      await file.writeAsBytes(newSalt, flush: true);

      return newSalt;
    }
  }

  /// Helper to get the file path
  static Future<File> _getSaltFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Generates a random salt of [_saltLength] bytes
  /// using a cryptographically secure random number generator.
  static Uint8List _generateRandomSalt() {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(_saltLength);
    int index = 0;
    while (index < _saltLength) {
      int value = random.nextInt(0x100000000); // 32 random bits
      for (int i = 0; i < 4 && index < _saltLength; i++) {
        bytes[index++] = value & 0xFF;
        value >>= 8;
      }
    }
    return bytes;
  }
}
