import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/auth/data/account_credential_rules.dart';

void main() {
  group('AccountCredentialRules.validateUsername', () {
    test('délègue aux règles de nom d\'utilisateur', () {
      expect(AccountCredentialRules.validateUsername('alice'), isNull);
      expect(AccountCredentialRules.validateUsername('ab'), isNotNull);
      expect(AccountCredentialRules.validateUsername('a b'), isNotNull);
    });
  });

  group('AccountCredentialRules.validatePassword', () {
    test('exige la même politique que le mot de passe du coffre', () {
      expect(AccountCredentialRules.validatePassword('Motdepasse1!'), isNull);
    });

    test('refuse un mot de passe vide', () {
      expect(AccountCredentialRules.validatePassword('   '), isNotNull);
    });

    test('refuse un mot de passe qui ne respecte pas toutes les règles', () {
      // Trop court.
      expect(AccountCredentialRules.validatePassword('Court1!'), isNotNull);
      // Pas de majuscule.
      expect(
        AccountCredentialRules.validatePassword('motdepasse1!'),
        isNotNull,
      );
      // Pas de chiffre.
      expect(
        AccountCredentialRules.validatePassword('Motdepasseee!'),
        isNotNull,
      );
      // Pas de caractère spécial.
      expect(
        AccountCredentialRules.validatePassword('Motdepasse123'),
        isNotNull,
      );
    });
  });
}
