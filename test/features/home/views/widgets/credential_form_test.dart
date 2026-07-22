import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';
import 'package:realmguard/features/home/data/custom_field.dart';
import 'package:realmguard/features/home/views/widgets/credential_form.dart';

/// Retrouve le champ de saisie portant ce libellé.
Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  late GlobalKey<FormState> formKey;
  late GlobalKey<CredentialFormState> formState;

  setUp(() {
    formKey = GlobalKey<FormState>();
    formState = GlobalKey<CredentialFormState>();
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    CredentialDraft? initial,
    bool enabled = true,
    VoidCallback? onChanged,
  }) async {
    // Surface haute : le formulaire est long, on évite les « off-screen ».
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CredentialForm(
              key: formState,
              formKey: formKey,
              profiles: const [],
              initial: initial,
              enabled: enabled,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('buildDraft reprend la saisie, en élaguant les blancs', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(_field('Titre'), '  GitHub  ');
    await tester.enterText(_field("Nom d'utilisateur"), ' me ');
    await tester.enterText(_field('Mot de passe'), 'Motdepasse1!');

    final draft = formState.currentState!.buildDraft();

    expect(draft.title, 'GitHub');
    expect(draft.username, 'me');
    expect(draft.password, 'Motdepasse1!');
    // Les champs laissés vides ne deviennent pas des chaînes vides.
    expect(draft.uri, isNull);
    expect(draft.notes, isNull);
  });

  testWidgets('les valeurs initiales pré-remplissent le formulaire', (
    tester,
  ) async {
    await pumpForm(
      tester,
      initial: const CredentialDraft(
        title: 'GitHub',
        username: 'octocat',
        favorite: true,
      ),
    );

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('octocat'), findsOneWidget);
    // Le favori est conservé même si l'utilisateur ne touche à rien.
    expect(formState.currentState!.buildDraft().favorite, isTrue);
  });

  testWidgets('un titre vide est refusé par la validation', (tester) async {
    await pumpForm(tester);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Veuillez saisir un titre.'), findsOneWidget);

    await tester.enterText(_field('Titre'), 'GitHub');
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('un champ personnalisé saisi se retrouve dans le brouillon', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.enterText(_field('Titre'), 'GitHub');

    await tester.tap(find.widgetWithText(TextButton, 'Ajouter un champ'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Libellé'), 'Code de secours');
    await tester.enterText(_field('Valeur'), '1234-5678');

    final fields = formState.currentState!.buildDraft().customFields;

    expect(fields, hasLength(1));
    expect(fields.single.label, 'Code de secours');
    expect(fields.single.value, '1234-5678');
  });

  testWidgets('un champ personnalisé resté vide est écarté du brouillon', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Ajouter un champ'));
    await tester.pumpAndSettle();

    // La ligne existe à l'écran mais ne doit pas polluer le brouillon.
    expect(_field('Libellé'), findsOneWidget);
    expect(formState.currentState!.buildDraft().customFields, isEmpty);
  });

  testWidgets('les champs personnalisés initiaux sont restitués', (
    tester,
  ) async {
    await pumpForm(
      tester,
      initial: const CredentialDraft(
        title: 'GitHub',
        customFields: [CustomField(label: 'PIN', value: '4242', secret: true)],
      ),
    );

    final fields = formState.currentState!.buildDraft().customFields;

    expect(fields, hasLength(1));
    expect(fields.single.label, 'PIN');
    expect(fields.single.secret, isTrue, reason: 'le marqueur secret survit');
  });

  testWidgets('onChanged prévient le parent à chaque frappe', (tester) async {
    var changes = 0;
    await pumpForm(tester, onChanged: () => changes++);

    await tester.enterText(_field('Titre'), 'GitHub');

    expect(changes, greaterThan(0));
  });

  testWidgets('enabled: false verrouille la saisie et l ajout de champ', (
    tester,
  ) async {
    await pumpForm(tester, enabled: false);

    final title = tester.widget<TextFormField>(_field('Titre'));
    expect(title.enabled, isFalse);

    final addButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Ajouter un champ'),
    );
    expect(addButton.onPressed, isNull);
  });
}
