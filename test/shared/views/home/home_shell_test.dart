import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realm_guard_mobile/shared/views/home/home_shell.dart';

Widget _harness() {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Text('VAULT_CHILD'),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets(
    'sélectionner l\'onglet Partage ne plante pas et affiche un placeholder',
    (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Onglet Vault par défaut : le contenu du coffre est affiché.
      expect(find.text('VAULT_CHILD'), findsOneWidget);

      // Sélection de l'onglet "Partage" (index 1) : auparavant -> RangeError.
      await tester.tap(find.text('Partage'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('VAULT_CHILD'), findsNothing);
      expect(find.text('Le partage arrive bientôt'), findsOneWidget);

      // Retour sur l'onglet "Vault" : le contenu du coffre revient.
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();
      expect(find.text('VAULT_CHILD'), findsOneWidget);
      expect(find.text('Le partage arrive bientôt'), findsNothing);
    },
  );
}
