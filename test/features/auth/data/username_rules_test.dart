import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/auth/data/username_rules.dart';

void main() {
  group('UsernameRules', () {
    test('accepte lettres, chiffres et « . _ - »', () {
      for (final ok in ['alice', 'bob', 'a_b-c.d', 'abc', 'A1.', 'user-42']) {
        expect(UsernameRules.validate(ok), isNull, reason: ok);
        expect(UsernameRules.isValid(ok), isTrue, reason: ok);
      }
    });

    test('refuse en dessous de la longueur minimale', () {
      expect(UsernameRules.minLength, 3);
      expect(UsernameRules.validate('ab'), isNotNull);
      expect(UsernameRules.validate(''), isNotNull);
      // Les espaces de bord ne comptent pas.
      expect(UsernameRules.validate('  x  '), isNotNull);
    });

    test('refuse espaces et caractères hors liste', () {
      for (final bad in ['a b', 'ab@c', 'abé', 'ab!', 'a/b']) {
        expect(UsernameRules.validate(bad), isNotNull, reason: bad);
        expect(UsernameRules.isValid(bad), isFalse, reason: bad);
      }
    });
  });
}
