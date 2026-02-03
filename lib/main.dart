import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/routes/app_router.dart';
import 'core/security/encryption_key_provider_impl.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );
  final secureStorage = const FlutterSecureStorage(aOptions: androidOptions);
  final encryptionKeyProvider = EncryptionKeyProviderImpl(secureStorage);

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
