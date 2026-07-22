import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/totp_draft.dart';
import 'package:realmguard/features/home/views/widgets/totp_form.dart';

const _validSecret = 'JBSWY3DPEHPK3PXP';

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  late GlobalKey<FormState> formKey;
  late GlobalKey<TotpFormState> formState;

  setUp(() {
    formKey = GlobalKey<FormState>();
    formState = GlobalKey<TotpFormState>();
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    TotpDraft? initial,
    bool enabled = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TotpForm(
              key: formState,
              formKey: formKey,
              profiles: const [],
              initial: initial,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('buildDraft élague le libellé et laisse le compte à null', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(_field('Libellé'), '  GitHub  ');
    await tester.enterText(_field('Secret (Base32)'), _validSecret);

    final draft = formState.currentState!.buildDraft();

    expect(draft.label, 'GitHub');
    expect(draft.account, isNull);
    expect(draft.secret, _validSecret);
  });

  testWidgets('le secret est normalisé : les espaces de saisie sont retirés', (
    tester,
  ) async {
    await pumpForm(tester);

    // Les secrets sont souvent affichés par groupes de 4 côté fournisseur.
    await tester.enterText(_field('Secret (Base32)'), 'JBSW Y3DP EHPK 3PXP');

    expect(formState.currentState!.buildDraft().secret, _validSecret);
  });

  testWidgets('les paramètres par défaut sont 6 chiffres / 30 s / SHA1', (
    tester,
  ) async {
    await pumpForm(tester);

    final draft = formState.currentState!.buildDraft();

    expect(draft.digits, 6);
    expect(draft.period, 30);
    expect(draft.algorithm, 'SHA1');
  });

  testWidgets('un libellé vide est refusé', (tester) async {
    await pumpForm(tester);
    await tester.enterText(_field('Secret (Base32)'), _validSecret);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Veuillez saisir un libellé.'), findsOneWidget);
  });

  testWidgets('un secret non Base32 est refusé, un secret valide passe', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.enterText(_field('Libellé'), 'GitHub');

    await tester.enterText(_field('Secret (Base32)'), '1189!!');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Secret Base32 invalide.'), findsOneWidget);

    await tester.enterText(_field('Secret (Base32)'), _validSecret);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('les valeurs initiales sont restituées, favori compris', (
    tester,
  ) async {
    await pumpForm(
      tester,
      initial: const TotpDraft(
        label: 'GitHub',
        secret: _validSecret,
        account: 'me@example.com',
        favorite: true,
      ),
    );

    // On vérifie le contrat (le brouillon reconstruit) plutôt que le rendu :
    // le champ « Libellé » a un hintText 'GitHub', donc find.text('GitHub')
    // matcherait aussi bien la valeur que le texte d'aide.
    final draft = formState.currentState!.buildDraft();
    expect(draft.label, 'GitHub');
    expect(draft.account, 'me@example.com');
    expect(draft.favorite, isTrue, reason: 'le favori ne doit pas être perdu');
  });

  testWidgets('enabled: false verrouille la saisie', (tester) async {
    await pumpForm(tester, enabled: false);

    expect(tester.widget<TextFormField>(_field('Libellé')).enabled, isFalse);
    expect(
      tester.widget<TextFormField>(_field('Secret (Base32)')).enabled,
      isFalse,
    );
  });
}
