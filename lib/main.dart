import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/autofill/views/autofill_app.dart';

void main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  _registerFontLicenses();

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  // Préférences de fonctionnalités chargées avant le premier rendu pour que
  // l'interface (onglets de l'accueil) reflète immédiatement le choix de
  // l'utilisateur.
  await featureFlagsController.load();

  FlutterNativeSplash.remove();

  runApp(const RealmGuard());
}

/// Entrypoint Dart dédié au remplissage automatique, exécuté par
/// `AutofillActivity` lorsque le service d'autofill de l'OS sollicite Realm
/// Guard. Séparé de [main] : ne démarre ni le routeur ni l'auto-lock, seulement
/// l'écran d'autofill.
@pragma('vm:entry-point')
void autofillEntryPoint() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cet entrypoint ne passe pas par main() : la surcharge SQLCipher doit être
  // ré-appliquée ici car le remplissage ouvre le coffre chiffré dans son isolate.
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  runApp(const AutofillApp());
}

/// Enregistre les licences OFL des polices embarquées (visibles dans la page
/// "Licences" de l'application).
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Plus Jakarta Sans'],
      await rootBundle.loadString('assets/fonts/OFL-PlusJakartaSans.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      const ['Space Grotesk'],
      await rootBundle.loadString('assets/fonts/OFL-SpaceGrotesk.txt'),
    );
  });
}

class RealmGuard extends StatefulWidget {
  const RealmGuard({super.key});

  @override
  State<RealmGuard> createState() => _RealmGuardState();
}

class _RealmGuardState extends State<RealmGuard> {
  @override
  void initState() {
    super.initState();
    // Auto-lock : verrouille le coffre en arrière-plan / après inactivité et
    // renvoie vers l'écran de déverrouillage.
    appLockController.attach(onLock: () => appRouter.go(AppRoutes.unlock));
  }

  @override
  void dispose() {
    appLockController.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le Listener (au-dessus de MaterialApp) capte chaque interaction pour
    // réarmer le compte à rebours d'inactivité, sans consommer les événements.
    return Listener(
      onPointerDown: (_) => appLockController.notifyInteraction(),
      onPointerMove: (_) => appLockController.notifyInteraction(),
      child: MaterialApp.router(
        title: 'Realm Guard',
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
