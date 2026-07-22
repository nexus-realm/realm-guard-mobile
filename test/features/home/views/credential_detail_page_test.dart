import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realmguard/features/home/views/credential_detail_page.dart';

import '../../../support/home_test_doubles.dart';

/// Harnais routé : la page navigue (retour après suppression), il lui faut un
/// routeur même quand le test ne l'exerce pas.
Widget _harness(FakeCredentialEditor repository) {
  final router = GoRouter(
    initialLocation: '/credential',
    routes: [
      GoRoute(
        path: '/credential',
        builder: (_, _) =>
            CredentialDetailPage(repository: repository, credentialId: 1),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  late FakeCredentialEditor repository;

  setUp(() => repository = FakeCredentialEditor());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(repository));
    // Surtout pas de pumpAndSettle ici : tant que le flux n'a rien émis, la page
    // affiche un indicateur de chargement dont l'animation ne se stabilise
    // jamais — pumpAndSettle partirait en timeout.
    await tester.pump();
  }

  testWidgets('affiche l identifiant émis par le flux', (tester) async {
    await pumpPage(tester);

    repository.controller.add(
      credentialWithProfile(1, 'GitHub', username: 'octocat'),
    );
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsWidgets);
    expect(find.text('octocat'), findsOneWidget);
  });

  testWidgets('annonce la disparition quand le flux émet null', (tester) async {
    await pumpPage(tester);

    repository.controller.add(null);
    await tester.pumpAndSettle();

    expect(find.text('Cet identifiant n\'existe plus.'), findsOneWidget);
  });

  testWidgets('le bouton Modifier bascule en mode édition', (tester) async {
    await pumpPage(tester);
    repository.controller.add(credentialWithProfile(1, 'GitHub'));
    await tester.pumpAndSettle();

    expect(find.text('Identifiant'), findsOneWidget);

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier l\'identifiant'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('enregistrer transmet le brouillon modifié au dépôt', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.controller.add(credentialWithProfile(1, 'GitHub'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Titre'), 'GitLab');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repository.updatedId, 1);
    expect(repository.updatedDraft?.title, 'GitLab');
  });

  testWidgets('annuler avec des modifications demande confirmation', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.controller.add(credentialWithProfile(1, 'GitHub'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Titre'), 'GitLab');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    // Garde-fou : on ne jette pas des modifications sans demander.
    expect(find.text('Abandonner les modifications ?'), findsOneWidget);

    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('Identifiant'), findsOneWidget, reason: 'retour lecture');
    expect(repository.updatedDraft, isNull, reason: 'rien n a été écrit');
  });

  testWidgets('« Continuer l édition » conserve les modifications en cours', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.controller.add(credentialWithProfile(1, 'GitHub'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Titre'), 'GitLab');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuer l\'édition'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier l\'identifiant'), findsOneWidget);
    expect(find.text('GitLab'), findsOneWidget, reason: 'la saisie est gardée');
  });

  testWidgets('basculer le favori écrit l état inversé', (tester) async {
    await pumpPage(tester);
    repository.controller.add(credentialWithProfile(1, 'GitHub'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    expect(repository.updatedDraft?.favorite, isTrue);
  });
}
