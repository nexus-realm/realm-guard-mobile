import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/security/key_derivator.dart';

void main() {
  group('KeyDerivator Unit Tests', () {
    final Uint8List validSalt = Uint8List.fromList(List.generate(16, (i) => i));

    group('deriveKeyFromPassword - Input Validation', () {
      test('should throw ArgumentError if password is empty', () async {
        expect(
          () => KeyDerivator.deriveKeyFromPassword('', validSalt),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Password must not be empty or blank.',
            ),
          ),
        );
      });

      test(
        'should throw ArgumentError if password is only whitespace',
        () async {
          expect(
            () => KeyDerivator.deriveKeyFromPassword('   ', validSalt),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'Password must not be empty or blank.',
              ),
            ),
          );
        },
      );
    });

    group('deriveKeyFromPassword - Functional Logic', () {
      test('should return a SecretKey of 32 bytes', () async {
        final key = await KeyDerivator.deriveKeyFromPassword(
          'password123',
          validSalt,
        );

        final bytes = await key.extractBytes();
        expect(bytes.length, equals(32));
      });

      test('should be deterministic (same input = same output)', () async {
        const password = 'my-secure-password';

        final key1 = await KeyDerivator.deriveKeyFromPassword(
          password,
          validSalt,
        );
        final key2 = await KeyDerivator.deriveKeyFromPassword(
          password,
          validSalt,
        );

        expect(await key1.extractBytes(), equals(await key2.extractBytes()));
      });

      test('should produce different keys for different passwords', () async {
        final key1 = await KeyDerivator.deriveKeyFromPassword(
          'password1',
          validSalt,
        );
        final key2 = await KeyDerivator.deriveKeyFromPassword(
          'password2',
          validSalt,
        );

        expect(
          await key1.extractBytes(),
          isNot(equals(await key2.extractBytes())),
        );
      });

      test('should produce different keys for different salts', () async {
        const password = 'identical-password';
        final differentSalt = Uint8List.fromList([1, 2, 3]);

        final key1 = await KeyDerivator.deriveKeyFromPassword(
          password,
          validSalt,
        );
        final key2 = await KeyDerivator.deriveKeyFromPassword(
          password,
          differentSalt,
        );

        expect(
          await key1.extractBytes(),
          isNot(equals(await key2.extractBytes())),
        );
      });
    });
  });
}
