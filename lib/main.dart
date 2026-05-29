import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  runApp(const RealmGuard());
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
