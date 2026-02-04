import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realm_guard_mobile/core/security/key_derivator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('KeyDerivator - Integration testing', () {
    testWidgets('Should generate a valide key derived from a password', (
      tester,
    ) async {
      // Arrange
      const password = "password123";
      final salt = Uint8List.fromList(List.generate(32, (index) => index));

      // Act
      final SecretKey derivedKey = await KeyDerivator.deriveKeyFromPassword(
        password,
        salt,
      );

      // Assert
      expect(derivedKey, isNotNull);
      final keyBytes = await derivedKey.extractBytes();
      expect(keyBytes.length, equals(32)); // Doit être de 32 bytes (256 bits)
    });

    testWidgets('Doit être déterministe (Même input = Même output)', (
      tester,
    ) async {
      // Pour une app de sécurité, il est vital que le même mot de passe donne
      // toujours la même clé, sinon l'utilisateur perd ses données.

      const password = "MonSuperMotDePasse";
      final salt = Uint8List.fromList(List.filled(32, 1)); // Sel rempli de '1'

      final key1 = await KeyDerivator.deriveKeyFromPassword(password, salt);
      final key2 = await KeyDerivator.deriveKeyFromPassword(password, salt);

      expect(key1, equals(key2));
    });

    testWidgets('Doit changer si le sel change (Sécurité)', (tester) async {
      const password = "password";
      final saltA = Uint8List.fromList(List.filled(32, 1));
      final saltB = Uint8List.fromList(List.filled(32, 2));

      final keyA = await KeyDerivator.deriveKeyFromPassword(password, saltA);
      final keyB = await KeyDerivator.deriveKeyFromPassword(password, saltB);

      expect(keyA, isNot(equals(keyB)));
    });
  });
}
