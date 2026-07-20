import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/domain_identity.dart';

void main() {
  group('DomainIdentity.extractDomain', () {
    test('retire schéma, www, chemin et port', () {
      expect(
        DomainIdentity.extractDomain('https://www.amazon.fr/gp/cart'),
        'amazon.fr',
      );
      expect(
        DomainIdentity.extractDomain('http://localhost:8080/login'),
        'localhost',
      );
      expect(DomainIdentity.extractDomain('github.com'), 'github.com');
    });

    test('retourne null pour une entrée vide ou absente', () {
      expect(DomainIdentity.extractDomain(null), isNull);
      expect(DomainIdentity.extractDomain('   '), isNull);
    });
  });

  group('DomainIdentity.from', () {
    test('utilise l\'initiale du domaine de l\'URL', () {
      final id = DomainIdentity.from(
        uri: 'https://amazon.fr',
        title: 'Courses',
      );
      expect(id.initial, 'A');
    });

    test('repli sur le titre quand l\'URL est absente', () {
      final id = DomainIdentity.from(uri: null, title: 'Gmail');
      expect(id.initial, 'G');
    });

    test('initiale ? quand ni URL ni titre exploitables', () {
      final id = DomainIdentity.from(uri: null, title: '');
      expect(id.initial, '?');
    });

    test('couleur déterministe : même domaine → même couleur', () {
      final a = DomainIdentity.from(uri: 'https://amazon.fr');
      final b = DomainIdentity.from(uri: 'https://www.amazon.fr/autre');
      expect(a.color, b.color);
    });
  });
}
