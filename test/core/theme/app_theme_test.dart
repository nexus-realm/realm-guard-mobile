import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test(
      'utilise les familles de polices embarquées (pas de fetch réseau)',
      () {
        final theme = AppTheme.darkTheme;

        // Familles natives déclarées dans pubspec `fonts:` (et non des noms
        // internes générés par google_fonts).
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Plus Jakarta Sans');
        expect(theme.textTheme.labelLarge?.fontFamily, 'Plus Jakarta Sans');
        expect(theme.textTheme.titleLarge?.fontFamily, 'Space Grotesk');
        expect(theme.textTheme.titleSmall?.fontFamily, 'Space Grotesk');
        expect(
          theme.appBarTheme.titleTextStyle?.fontFamily,
          'Plus Jakarta Sans',
        );
      },
    );
  });
}
