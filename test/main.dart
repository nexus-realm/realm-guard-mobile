// Check app initialization and theme application
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realm_guard_mobile/main.dart';

void main() {
  testWidgets('App initializes and applies dark theme', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const RealmGuard());

    // Verify that the app title is correct
    expect(find.text('Welcome to Realm Guard!'), findsOneWidget);

    // Verify that the dark theme is applied
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });
}