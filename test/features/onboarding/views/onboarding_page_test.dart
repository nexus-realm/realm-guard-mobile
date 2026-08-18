import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realmguard/features/onboarding/views/onboarding_page.dart';

import '../../../support/auth_test_doubles.dart';
import '../../../support/feature_flags_test_doubles.dart';
import '../../../support/onboarding_test_doubles.dart';

/// Harnais routé : les cartes « lier » / « récupérer » poussent leur écran, et
/// la fin du parcours fait `go` vers l'accueil.
Widget _harness() {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => OnboardingPage(
          onboardingStorageService: InMemoryOnboardingStorageService(),
          vaultService: FakeVaultService(),
          featureFlagsController: featureFlagsControllerWith(),
          authService: FakeAuthService(),
          biometricStorageService: FakeBiometricStorageService(),
        ),
      ),
      GoRoute(path: '/home', builder: (_, _) => const SizedBox.shrink()),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

/// `ViewTitle` affiche son titre en MAJUSCULES (la casse d'origine n'est gardée
/// que dans le libellé sémantique) — on cible donc le rendu réel.
Finder _viewTitle(String title) => find.text(title.toUpperCase());

void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    // Pompes explicites plutôt que pumpAndSettle : tant que `initialize()` n'a
    // pas répondu, la page affiche un indicateur qui anime en boucle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Amène le parcours jusqu'à l'étape « Synchronisation ».
  Future<void> goToSyncStep(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Commencer'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('démarre sur l écran de bienvenue', (tester) async {
    await pumpOnboarding(tester);

    expect(_viewTitle('Bienvenue sur Realm Guard_'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('l étape synchronisation n offre que deux choix', (tester) async {
    await goToSyncStep(tester);

    // Restructuration du lot B : plus de liste de 4 boutons entassés.
    expect(find.text('Activer la synchronisation'), findsOneWidget);
    expect(find.text('Continuer hors-ligne'), findsOneWidget);
    // Les options « en ligne » ne sont pas exposées à ce niveau.
    expect(find.text('Créer un compte'), findsNothing);
  });

  testWidgets('« Activer » ouvre la page En ligne et ses trois options', (
    tester,
  ) async {
    await goToSyncStep(tester);

    await tester.tap(find.text('Activer la synchronisation'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_viewTitle('En ligne_'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Lier cet appareil'), findsOneWidget);
    expect(find.text('Récupérer mon coffre'), findsOneWidget);
  });

  testWidgets('« Retour » ramène au choix de synchronisation', (tester) async {
    await goToSyncStep(tester);
    await tester.tap(find.text('Activer la synchronisation'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Retour'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Activer la synchronisation'), findsOneWidget);
    expect(find.text('Créer un compte'), findsNothing);
  });

  testWidgets('« Créer un compte » affiche le formulaire d inscription', (
    tester,
  ) async {
    await goToSyncStep(tester);
    await tester.tap(find.text('Activer la synchronisation'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Créer un compte'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_viewTitle('Créer un compte_'), findsOneWidget);
    expect(find.text('Nom d\'utilisateur'), findsOneWidget);
    expect(find.text('Mot de passe du compte'), findsOneWidget);
  });

  testWidgets('« Continuer hors-ligne » mène à l étape mot de passe', (
    tester,
  ) async {
    await goToSyncStep(tester);

    await tester.tap(find.text('Continuer hors-ligne'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_viewTitle('Mot de passe_'), findsOneWidget);
    expect(find.text('Valider le mot de passe'), findsOneWidget);
  });
}
