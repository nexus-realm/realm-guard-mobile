import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
