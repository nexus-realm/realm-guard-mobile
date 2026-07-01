import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/database/app_database.dart';
import 'package:realm_guard_mobile/features/autofill/data/autofill_matcher.dart';

Credential _credential(int id, String title, String? uri) => Credential(
  id: id,
  title: title,
  uri: uri,
  customFields: '[]',
  favorite: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('AutofillMatcher.matchByDomain', () {
    final creds = [
      _credential(1, 'GitHub', 'https://github.com/login'),
      _credential(2, 'GitLab', 'https://www.gitlab.com'),
      _credential(3, 'Mail', 'login.example.com'),
      _credential(4, 'Sans URL', null),
      _credential(5, 'Piège', 'https://github.com.evil.com'),
    ];

    test('correspondance exacte de domaine', () {
      final result = AutofillMatcher.matchByDomain(creds, {'github.com'});
      expect(result.map((c) => c.title), ['GitHub']);
    });

    test('ignore le préfixe www', () {
      final result = AutofillMatcher.matchByDomain(creds, {'gitlab.com'});
      expect(result.map((c) => c.title), ['GitLab']);
    });

    test('gère les sous-domaines (identifiant sous-domaine du demandé)', () {
      final result = AutofillMatcher.matchByDomain(creds, {'example.com'});
      expect(result.map((c) => c.title), ['Mail']);
    });

    test('domaine demandé sous-domaine de l\'identifiant', () {
      final result = AutofillMatcher.matchByDomain(creds, {'login.github.com'});
      expect(result.map((c) => c.title), ['GitHub']);
    });

    test('ne correspond pas à un hôte piège suffixé', () {
      final result = AutofillMatcher.matchByDomain(creds, {'evil.com'});
      // Seul le piège se termine par evil.com ; github.com n'y correspond pas.
      expect(result.map((c) => c.title), ['Piège']);
    });

    test('domaines demandés vides => aucune correspondance', () {
      expect(AutofillMatcher.matchByDomain(creds, const {}), isEmpty);
    });

    test('domaine sans correspondance => vide', () {
      expect(AutofillMatcher.matchByDomain(creds, {'unknown.test'}), isEmpty);
    });
  });
}
