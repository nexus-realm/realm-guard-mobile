import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/shared/widgets/password_form.dart';

void main() {
  testWidgets(
    'ne dispose pas les contrôleurs fournis par le parent quand il est démonté',
    (tester) async {
      final passwordController = TextEditingController();
      final confirmationController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      // 1) Monte le formulaire avec des contrôleurs possédés par le test (parent).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordForm(
              formKey: formKey,
              passwordController: passwordController,
              passwordConfirmationController: confirmationController,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Motdepasse1!');
      expect(passwordController.text, 'Motdepasse1!');

      // 2) Démonte PasswordForm (équivaut au changement d'étape onboarding).
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      // 3) Les contrôleurs doivent rester VALIDES : c'est au parent de les
      //    disposer. Si PasswordForm les avait disposés, ces appels
      //    lèveraient "used after being disposed".
      expect(passwordController.dispose, returnsNormally);
      expect(confirmationController.dispose, returnsNormally);
    },
  );
}
