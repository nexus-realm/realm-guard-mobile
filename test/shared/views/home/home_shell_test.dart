import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realmguard/shared/views/home/home_shell.dart';

Widget _harness() {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const Text('VAULT_CHILD')),
        ],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

/// Le placeholder "Partage" est-il réellement visible (pas seulement présent
/// dans l'arbre mais masqué par l'IndexedStack via Offstage) ?
bool _comingSoonVisible(WidgetTester tester) {
  final finder = find.text('Le partage arrive bientôt');
  if (finder.evaluate().isEmpty) return false;
  final offstage = find
      .ancestor(of: finder, matching: find.byType(Offstage))
      .evaluate()
      .map((e) => e.widget as Offstage);
  return offstage.every((o) => !o.offstage);
}

void main() {
  testWidgets(
    'le va-et-vient entre onglets ne plante pas et bascule le placeholder',
    (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Onglet Vault par défaut : le contenu du coffre est affiché, pas le
      // placeholder.
      expect(find.text('VAULT_CHILD'), findsOneWidget);
      expect(_comingSoonVisible(tester), isFalse);

      // Sélection de l'onglet "Partage" : auparavant -> RangeError.
      await tester.tap(find.text('Partage'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_comingSoonVisible(tester), isTrue);

      // Retour "Vault" : auparavant -> "deactivated widget's ancestor" /
      // PopScope / GlobalKey dupliquée.
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_comingSoonVisible(tester), isFalse);

      // Second aller-retour pour confirmer la stabilité.
      await tester.tap(find.text('Partage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('VAULT_CHILD'), findsOneWidget);
    },
  );
}
