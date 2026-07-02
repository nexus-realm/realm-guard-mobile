import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'autofill_dispatcher.dart';

/// Application Flutter exécutée par `AutofillActivity` via l'entrypoint
/// `autofillEntryPoint`, lorsque le service d'autofill de l'OS sollicite Realm
/// Guard. Aiguille vers le remplissage ou la sauvegarde selon la requête.
class AutofillApp extends StatelessWidget {
  const AutofillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const AutofillDispatcher(),
    );
  }
}
