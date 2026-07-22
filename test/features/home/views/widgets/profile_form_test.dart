import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/profile_draft.dart';
import 'package:realmguard/features/home/views/widgets/profile_form.dart';

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  late GlobalKey<FormState> formKey;
  late GlobalKey<ProfileFormState> formState;

  setUp(() {
    formKey = GlobalKey<FormState>();
    formState = GlobalKey<ProfileFormState>();
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    ProfileDraft? initial,
    bool enabled = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileForm(
              key: formState,
              formKey: formKey,
              initial: initial,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('buildDraft élague le nom et laisse la note à null', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(_field('Nom'), '  Perso  ');

    final draft = formState.currentState!.buildDraft();

    expect(draft.name, 'Perso');
    expect(draft.note, isNull);
  });

  testWidgets(
    'les lignes de liste laissées vides ne polluent pas le brouillon',
    (tester) async {
      await pumpForm(tester);
      await tester.enterText(_field('Nom'), 'Perso');

      // Une ligne vide est toujours affichée pour inviter à la saisie…
      expect(_field('Email 1'), findsOneWidget);

      // …mais elle ne doit produire aucune entrée.
      final draft = formState.currentState!.buildDraft();
      expect(draft.emails, isEmpty);
      expect(draft.usernames, isEmpty);
      expect(draft.phoneNumbers, isEmpty);
    },
  );

  testWidgets(
    'une valeur saisie dans une liste se retrouve dans le brouillon',
    (tester) async {
      await pumpForm(tester);

      await tester.enterText(_field('Nom'), 'Perso');
      await tester.enterText(_field('Email 1'), ' me@example.com ');
      await tester.enterText(_field('Téléphone 1'), '0600000000');

      final draft = formState.currentState!.buildDraft();

      expect(draft.emails, ['me@example.com'], reason: 'la valeur est élaguée');
      expect(draft.phoneNumbers, ['0600000000']);
      expect(draft.usernames, isEmpty);
    },
  );

  testWidgets('un nom vide est refusé par la validation', (tester) async {
    await pumpForm(tester);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Veuillez saisir un nom de profil.'), findsOneWidget);

    await tester.enterText(_field('Nom'), 'Perso');
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('les valeurs initiales sont restituées, couleur comprise', (
    tester,
  ) async {
    await pumpForm(
      tester,
      initial: const ProfileDraft(
        name: 'Perso',
        emails: ['a@b.c', 'd@e.f'],
        usernames: ['octocat'],
        color: 0xFFDAEE00,
        note: 'Compte principal',
      ),
    );

    final draft = formState.currentState!.buildDraft();

    expect(draft.name, 'Perso');
    expect(draft.emails, ['a@b.c', 'd@e.f']);
    expect(draft.usernames, ['octocat']);
    expect(draft.color, 0xFFDAEE00);
    expect(draft.note, 'Compte principal');
  });

  testWidgets('enabled: false verrouille la saisie', (tester) async {
    await pumpForm(tester, enabled: false);

    expect(tester.widget<TextFormField>(_field('Nom')).enabled, isFalse);
  });
}
