import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/auth/data/account_id.dart';

void main() {
  group('AccountId', () {
    test('round-trip UUID → octets → UUID', () {
      const uuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

      final bytes = AccountId.toBytes(uuid);

      expect(bytes.length, 16);
      expect(AccountId.fromBytes(bytes), uuid);
    });

    test('encode les octets attendus (ordre big-endian du texte)', () {
      final bytes = AccountId.toBytes('00000000-0000-0000-0000-000000000001');

      expect(bytes.first, 0);
      expect(bytes.last, 1);
    });

    test('accepte un UUID sans tirets', () {
      final withDashes = AccountId.toBytes(
        '3f2504e0-4f89-41d3-9a0c-0305e82c3301',
      );
      final without = AccountId.toBytes('3f2504e04f8941d39a0c0305e82c3301');

      expect(without, withDashes);
    });

    test('rejette une longueur invalide', () {
      expect(() => AccountId.toBytes('trop-court'), throwsFormatException);
      expect(() => AccountId.fromBytes(Uint8List(15)), throwsFormatException);
    });

    test('rejette un caractère non hexadécimal', () {
      expect(
        () => AccountId.toBytes('zzzzzzzz-4f89-41d3-9a0c-0305e82c3301'),
        throwsFormatException,
      );
    });
  });
}
