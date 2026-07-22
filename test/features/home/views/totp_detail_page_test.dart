import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realmguard/features/home/views/totp_detail_page.dart';

import '../../../support/home_test_doubles.dart';

Widget _harness(FakeTotpEditor repository) {
  final router = GoRouter(
    initialLocation: '/totp',
    routes: [
      GoRoute(
        path: '/totp',
        builder: (_, _) => TotpDetailPage(repository: repository, totpId: 1),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  late FakeTotpEditor repository;

  setUp(() => repository = FakeTotpEditor());

  /// ⚠️ Aucun `pumpAndSettle` dans ce fichier : la page anime en continu
  /// (indicateur de chargement, puis compteur de validité du code) — il partirait
  /// systématiquement en timeout. On avance donc image par image.
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(repository));
    await tester.pump();
  }

  testWidgets('affiche le TOTP émis par le flux', (tester) async {
    await pumpPage(tester);

    repository.controller.add(
      totpWithProfile(1, 'GitHub', account: 'me@example.com'),
    );
    await tester.pump();

    expect(find.text('TOTP'), findsOneWidget);
    expect(find.text('me@example.com'), findsOneWidget);
  });

  testWidgets('annonce la disparition quand le flux émet null', (tester) async {
    await pumpPage(tester);

    repository.controller.add(null);
    await tester.pump();

    expect(find.text('Ce code TOTP n\'existe plus.'), findsOneWidget);
  });

  testWidgets('le bouton Modifier bascule en mode édition', (tester) async {
    await pumpPage(tester);
    repository.controller.add(totpWithProfile(1, 'GitHub'));
    await tester.pump();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pump();

    expect(find.text('Modifier le TOTP'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('enregistrer transmet le brouillon modifié au dépôt', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.controller.add(totpWithProfile(1, 'GitHub'));
    await tester.pump();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pump();

    await tester.enterText(_field('Libellé'), 'GitLab');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.updatedId, 1);
    expect(repository.updatedDraft?.label, 'GitLab');
    // Le secret n'a pas été touché : il doit être conservé tel quel.
    expect(repository.updatedDraft?.secret, validTotpSecret);
  });

  testWidgets('annuler avec des modifications demande confirmation', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.controller.add(totpWithProfile(1, 'GitHub'));
    await tester.pump();

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pump();
    await tester.enterText(_field('Libellé'), 'GitLab');
    await tester.tap(find.text('Annuler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Abandonner les modifications ?'), findsOneWidget);

    await tester.tap(find.text('Abandonner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.updatedDraft, isNull, reason: 'rien n a été écrit');
  });
}
