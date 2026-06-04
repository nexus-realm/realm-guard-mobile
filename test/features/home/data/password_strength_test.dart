import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/home/data/password_strength.dart';

void main() {
  group('PasswordStrength.evaluate', () {
    test('mot de passe vide = très faible, 0 segment', () {
      final s = PasswordStrength.evaluate('');
      expect(s.level, PasswordStrengthLevel.veryWeak);
      expect(s.filledSegments, 1); // la barre montre toujours au moins 1 cran
      expect(s.score, 0);
    });

    test('court et simple = très faible', () {
      final s = PasswordStrength.evaluate('abc');
      expect(s.level, PasswordStrengthLevel.veryWeak);
    });

    test('court mais varié reste plafonné (longueur < 8)', () {
      // 4 classes mais seulement 6 caractères → plafonné.
      final s = PasswordStrength.evaluate('aB3\$x!');
      expect(s.level, PasswordStrengthLevel.veryWeak);
    });

    test('long et très varié = très fort', () {
      final s = PasswordStrength.evaluate('Tr0ub4dour&3xtra!Long');
      expect(s.level, PasswordStrengthLevel.veryStrong);
      expect(s.filledSegments, PasswordStrength.segmentCount);
    });

    test('moyen : 12 caractères, 2 classes', () {
      final s = PasswordStrength.evaluate('azertyuiopqs'); // 12, minuscules
      expect(
        s.level,
        anyOf(PasswordStrengthLevel.weak, PasswordStrengthLevel.fair),
      );
    });

    test('la force est (faiblement) monotone avec la complexité', () {
      final weak = PasswordStrength.evaluate('abcdefg');
      final medium = PasswordStrength.evaluate('Abcdefg1');
      final strong = PasswordStrength.evaluate('Abcdefg1!xyz');
      expect(weak.score, lessThan(medium.score));
      expect(medium.score, lessThanOrEqualTo(strong.score));
    });

    test('chaque niveau a un libellé et une couleur', () {
      for (final pwd in ['a', 'abcdefgh', 'Abcdefg1', 'Abcdefg1!xyzKLMNO']) {
        final s = PasswordStrength.evaluate(pwd);
        expect(s.label, isNotEmpty);
        expect(s.filledSegments, inInclusiveRange(1, 4));
      }
    });
  });
}
