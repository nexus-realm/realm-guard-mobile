import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Application Flutter minimale exécutée par `AutofillActivity` via l'entrypoint
/// `autofillEntryPoint`, lorsque le service d'autofill de l'OS sollicite Realm
/// Guard.
///
/// Lot 1 (activation) : écran d'attente. Le remplissage réel — déverrouillage
/// du coffre, correspondance app/domaine, sélection puis renvoi du résultat via
/// `AutofillService().resultWithDatasets(...)` — sera implémenté au lot 2.
class AutofillApp extends StatelessWidget {
  const AutofillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const _AutofillPlaceholderPage(),
    );
  }
}

class _AutofillPlaceholderPage extends StatelessWidget {
  const _AutofillPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 56,
                color: AppColors.mainColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Realm Guard',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Le remplissage automatique sera bientôt disponible.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
