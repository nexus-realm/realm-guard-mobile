import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  runApp(const RealmGuard());
}

class RealmGuard extends StatelessWidget {
  const RealmGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Realm Guard',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
