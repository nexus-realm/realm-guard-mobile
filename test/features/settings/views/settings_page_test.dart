import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flag.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flags_controller.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';
import 'package:realm_guard_mobile/features/settings/service/app_reset_service.dart';
import 'package:realm_guard_mobile/features/settings/views/settings_page.dart';

import '../../../support/feature_flags_test_doubles.dart';

class _FakeBiometricStorageService extends BiometricStorageService {
  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;
}

class _FakeVaultService extends VaultService {}

class _FakeAppResetService extends AppResetService {}

Widget _harness(FeatureFlagsController flags) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => SettingsPage(
          vaultService: _FakeVaultService(),
          biometricService: _FakeBiometricStorageService(),
          resetService: _FakeAppResetService(),
          featureFlagsController: flags,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets(
    'la section Fonctionnalités active/désactive la gestion des TOTP',
    (tester) async {
      final flags = featureFlagsControllerWith();
      await flags.load();

      await tester.pumpWidget(_harness(flags));
      await tester.pumpAndSettle();

      // Un interrupteur par fonctionnalité du registre, activé par défaut.
      final totpSwitch = find.widgetWithText(
        SwitchListTile,
        FeatureFlag.totp.label,
      );
      expect(totpSwitch, findsOneWidget);
      expect(flags.isEnabled(FeatureFlag.totp), isTrue);

      await tester.tap(totpSwitch);
      await tester.pumpAndSettle();
      expect(flags.isEnabled(FeatureFlag.totp), isFalse);

      // Réactivation : l'interrupteur repasse à l'état activé.
      await tester.tap(totpSwitch);
      await tester.pumpAndSettle();
      expect(flags.isEnabled(FeatureFlag.totp), isTrue);
    },
  );
}
