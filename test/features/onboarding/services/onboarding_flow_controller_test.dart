import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flag.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_flow_controller.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';

import '../../../support/feature_flags_test_doubles.dart';

class InMemoryOnboardingStorageService extends OnboardingStorageService {
  OnboardingProgress _progress = OnboardingProgress.initial();

  @override
  Future<OnboardingProgress> loadProgress() async {
    return _progress;
  }

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    _progress = progress;
  }

  @override
  Future<void> clearProgress() async {
    _progress = OnboardingProgress.initial();
  }
}

class FakeVaultService extends VaultService {
  bool shouldThrow = false;
  String? lastPassword;
  bool isLocked = false;

  @override
  Future<void> unlockWithMasterPassword(String masterPassword) async {
    if (shouldThrow) {
      throw Exception('Vault error');
    }
    lastPassword = masterPassword;
  }

  @override
  void lockVault() {
    isLocked = true;
  }
}

class FakeBiometricStorageService extends BiometricStorageService {
  bool clearWasCalled = false;
  bool isAvailable = true;
  bool? biometricEnabledValue;

  @override
  Future<bool> isBiometricAvailable() async {
    return isAvailable;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    biometricEnabledValue = enabled;
  }

  @override
  Future<void> clearDerivedKey() async {
    clearWasCalled = true;
  }
}

void main() {
  group('OnboardingFlowController', () {
    test('loads existing progress at initialization', () async {
      final storage = InMemoryOnboardingStorageService();
      await storage.saveProgress(
        OnboardingProgress.initial().markStepCompleted(OnboardingStep.welcome),
      );

      final controller = OnboardingFlowController(
        onboardingStorageService: storage,
        vaultService: FakeVaultService(),
        biometricStorageService: FakeBiometricStorageService(),
        featureFlagsController: featureFlagsControllerWith(),
      );

      await controller.initialize();

      expect(controller.currentStep, OnboardingStep.masterPassword);
      expect(
        controller.progress.completedSteps.contains(OnboardingStep.welcome),
        isTrue,
      );
    });

    test('completes master password step when inputs are valid', () async {
      final storage = InMemoryOnboardingStorageService();
      final vault = FakeVaultService();

      final controller = OnboardingFlowController(
        onboardingStorageService: storage,
        vaultService: vault,
        biometricStorageService: FakeBiometricStorageService(),
        featureFlagsController: featureFlagsControllerWith(),
      );

      await controller.initialize();
      await controller.completeWelcomeStep();

      final success = await controller.completeMasterPasswordStep(
        'Motdepasse1!',
        'Motdepasse1!',
      );

      expect(success, isTrue);
      expect(vault.lastPassword, 'Motdepasse1!');
      expect(vault.isLocked, isTrue);
      expect(
        controller.progress.completedSteps.contains(
          OnboardingStep.masterPassword,
        ),
        isTrue,
      );
    });

    test(
      'TOTP choice step follows biometrics and completes onboarding',
      () async {
        final storage = InMemoryOnboardingStorageService();
        final vault = FakeVaultService();
        final biometrics = FakeBiometricStorageService()..isAvailable = true;

        final controller = OnboardingFlowController(
          onboardingStorageService: storage,
          vaultService: vault,
          biometricStorageService: biometrics,
          featureFlagsController: featureFlagsControllerWith(),
        );

        await controller.initialize();
        await controller.completeWelcomeStep();
        await controller.completeMasterPasswordStep(
          'Motdepasse1!',
          'Motdepasse1!',
        );
        await controller.completeBiometricStep(false);

        // La biométrie n'est plus la dernière étape : le choix TOTP la suit.
        expect(biometrics.clearWasCalled, isTrue);
        expect(biometrics.biometricEnabledValue, isFalse);
        expect(controller.currentStep, OnboardingStep.totpChoice);
        expect(controller.isCompleted, isFalse);

        await controller.completeTotpChoiceStep(true);

        expect(controller.currentStep, isNull);
        expect(controller.isCompleted, isTrue);
        expect(controller.progress.biometricEnabled, isFalse);
      },
    );

    test(
      'records the TOTP choice through the feature flags controller',
      () async {
        final storage = InMemoryOnboardingStorageService();
        final flags = featureFlagsControllerWith();

        final controller = OnboardingFlowController(
          onboardingStorageService: storage,
          vaultService: FakeVaultService(),
          biometricStorageService: FakeBiometricStorageService(),
          featureFlagsController: flags,
        );

        await controller.initialize();
        await controller.completeWelcomeStep();
        await controller.completeMasterPasswordStep(
          'Motdepasse1!',
          'Motdepasse1!',
        );
        await controller.completeBiometricStep(true);

        await controller.completeTotpChoiceStep(false);

        expect(flags.isEnabled(FeatureFlag.totp), isFalse);
        expect(controller.isCompleted, isTrue);
        expect(
          controller.progress.completedSteps.contains(
            OnboardingStep.totpChoice,
          ),
          isTrue,
        );
      },
    );

    test(
      'shows the TOTP step (not completion) when biometrics are unavailable',
      () async {
        final storage = InMemoryOnboardingStorageService();
        final vault = FakeVaultService();
        final biometrics = FakeBiometricStorageService()..isAvailable = false;

        final controller = OnboardingFlowController(
          onboardingStorageService: storage,
          vaultService: vault,
          biometricStorageService: biometrics,
          featureFlagsController: featureFlagsControllerWith(),
        );

        await controller.initialize();
        await controller.completeWelcomeStep();
        await controller.completeMasterPasswordStep(
          'Motdepasse1!',
          'Motdepasse1!',
        );

        // Biométrie indisponible : welcome → masterPassword → totpChoice (3 étapes).
        expect(controller.currentStep, OnboardingStep.totpChoice);
        expect(controller.totalStepCount, 3);
        expect(controller.isCompleted, isFalse);

        await controller.completeTotpChoiceStep(true);

        expect(controller.currentStep, isNull);
        expect(controller.isCompleted, isTrue);
        expect(
          controller.progress.completedSteps.contains(
            OnboardingStep.biometricChoice,
          ),
          isFalse,
        );
      },
    );
  });
}
