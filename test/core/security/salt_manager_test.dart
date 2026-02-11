import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realm_guard_mobile/core/exceptions/security_exception.dart';
import 'package:realm_guard_mobile/core/security/salt_manager.dart';

/// Mock pour simuler path_provider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory
        .systemTemp
        .path; // Utilise le dossier temp de l'OS pour les tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File saltFile;

  setUp(() async {
    // Initialise le mock de path_provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Nettoyage avant chaque test
    tempDir = Directory(Directory.systemTemp.path);
    saltFile = File('${tempDir.path}/realmguard_security_metadata.salt');
    if (await saltFile.exists()) {
      await saltFile.delete();
    }
  });

  group('SaltManager Tests', () {
    test(
      'Should generate and save a new salt if file does not exist',
      () async {
        // Act
        final salt = await SaltManager.getOrGenerateSalt();

        // Assert
        expect(salt.length, equals(32));
        expect(await saltFile.exists(), isTrue);

        final savedBytes = await saltFile.readAsBytes();
        expect(savedBytes, equals(salt));
      },
    );

    test('Should retrieve the existing salt if file already exists', () async {
      // Arrange
      final existingSalt = Uint8List.fromList(List.generate(32, (i) => i));
      await saltFile.writeAsBytes(existingSalt);

      // Act
      final retrievedSalt = await SaltManager.getOrGenerateSalt();

      // Assert
      expect(retrievedSalt, equals(existingSalt));
    });

    test(
      'Should throw SecurityException if salt file is corrupted (wrong length)',
      () async {
        // Arrange
        final corruptSalt = Uint8List.fromList([1, 2, 3]);
        await saltFile.writeAsBytes(corruptSalt);

        // Act & Assert
        expect(
          () => SaltManager.getOrGenerateSalt(),
          throwsA(isA<SecurityException>()),
        );
      },
    );

    test('Generated salts should be unique (Randomness check)', () async {
      // Arrange
      final salt1 = await SaltManager.getOrGenerateSalt();

      // Supprimer le fichier pour forcer une nouvelle génération
      await saltFile.delete();

      // Act
      final salt2 = await SaltManager.getOrGenerateSalt();

      // Assert
      expect(
        salt1,
        isNot(equals(salt2)),
        reason: "Two generated salts should not be identical.",
      );
    });
  });
}
