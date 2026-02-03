import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class SaltManager {
  static const int _saltLength = 32;
  static const String _fileName = 'realmguard_security_metadata.salt';

  /// Retrieves the existing salt or generates a new one if it's a new install.
  /// Generated salt is stored on disk.
  /// Salt is not a secret but must be unique and persistent.
  Future<Uint8List> getOrGenerateSalt() async {
    final file = await _getSaltFile();

    if (await file.exists()) {
      // 1. Existing user: Read the salt from disk
      final bytes = await file.readAsBytes();

      if (bytes.length != _saltLength) {
        throw Exception("Corrupted salt file. Security risk.");
      }
      return bytes;
    } else {
      final newSalt = _generateRandomSalt();

      await file.writeAsBytes(newSalt, flush: true);

      return newSalt;
    }
  }

  /// Helper to get the file path
  Future<File> _getSaltFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Cryptographically secure random generator
  Uint8List _generateRandomSalt() {
    final random = Random.secure();
    final values = List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return Uint8List.fromList(values);
  }
}
