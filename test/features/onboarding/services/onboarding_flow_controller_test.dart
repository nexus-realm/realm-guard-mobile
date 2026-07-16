import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/feature_flags/feature_flag.dart';
import 'package:realmguard/features/auth/data/auth_exception.dart';
import 'package:realmguard/features/onboarding/service/onboarding_flow_controller.dart';
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart';
import 'package:realmguard/features/onboarding/data/onboarding_step.dart';
import 'package:realmguard/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realmguard/core/security/biometric_storage_service.dart';
import 'package:realmguard/core/security/vault_service.dart';

import '../../../support/auth_test_doubles.dart';
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
        authService: FakeAuthService(),
      );

      await controller.initialize();

      expect(controller.currentStep, OnboardingStep.syncChoice);
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
        authService: FakeAuthService(),
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
      'sync choice comes right after welcome, before master password',
      () async {
        final controller = OnboardingFlowController(
          onboardingStorageService: InMemoryOnboardingStorageService(),
          vaultService: FakeVaultService(),
          biometricStorageService: FakeBiometricStorageService(),
          featureFlagsController: featureFlagsControllerWith(),
          authService: FakeAuthService(),
        );

        await controller.initialize();
        expect(controller.currentStep, OnboardingStep.welcome);

        await controller.completeWelcomeStep();
        expect(controller.currentStep, OnboardingStep.syncChoice);

        await controller.completeSyncStep();
        expect(controller.currentStep, OnboardingStep.masterPassword);
      },
    );

    test('full flow (welcome→sync→master→biometrics→totp) completes', () async {
      final vault = FakeVaultService();
      final biometrics = FakeBiometricStorageService()..isAvailable = true;

      final controller = OnboardingFlowController(
        onboardingStorageService: InMemoryOnboardingStorageService(),
        vaultService: vault,
        biometricStorageService: biometrics,
        featureFlagsController: featureFlagsControllerWith(),
        authService: FakeAuthService(),
      );

      await controller.initialize();
      await controller.completeWelcomeStep();
      await controller.completeSyncStep();
      await controller.completeMasterPasswordStep(
        'Motdepasse1!',
        'Motdepasse1!',
      );
      expect(controller.currentStep, OnboardingStep.biometricChoice);

      await controller.completeBiometricStep(false);
      expect(controller.currentStep, OnboardingStep.totpChoice);

      await controller.completeTotpChoiceStep(true);

      expect(controller.currentStep, isNull);
      expect(controller.isCompleted, isTrue);
      expect(controller.progress.biometricEnabled, isFalse);
      expect(vault.lastPassword, 'Motdepasse1!');
    });

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
          authService: FakeAuthService(),
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
        expect(
          controller.progress.completedSteps.contains(
            OnboardingStep.totpChoice,
          ),
          isTrue,
        );

        // Onboarding non terminé tant que le choix de synchronisation n'est pas fait.
        expect(controller.isCompleted, isFalse);
        await controller.completeSyncStep();
        expect(controller.isCompleted, isTrue);
      },
    );

    test(
      'skips only biometrics when unavailable (welcome→sync→master→totp)',
      () async {
        final vault = FakeVaultService();
        final biometrics = FakeBiometricStorageService()..isAvailable = false;

        final controller = OnboardingFlowController(
          onboardingStorageService: InMemoryOnboardingStorageService(),
          vaultService: vault,
          biometricStorageService: biometrics,
          featureFlagsController: featureFlagsControllerWith(),
          authService: FakeAuthService(),
        );

        await controller.initialize();
        await controller.completeWelcomeStep();
        await controller.completeSyncStep();

        // Biométrie indisponible : welcome → sync → master → totp (4 étapes).
        expect(controller.totalStepCount, 4);
        expect(controller.currentStep, OnboardingStep.masterPassword);

        await controller.completeMasterPasswordStep(
          'Motdepasse1!',
          'Motdepasse1!',
        );

        expect(controller.currentStep, OnboardingStep.totpChoice);
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

    test(
      'registerSyncAccount opens a session and can complete the step',
      () async {
        final auth = FakeAuthService();
        final controller = OnboardingFlowController(
          onboardingStorageService: InMemoryOnboardingStorageService(),
          vaultService: FakeVaultService(),
          biometricStorageService: FakeBiometricStorageService(),
          featureFlagsController: featureFlagsControllerWith(),
          authService: auth,
        );

        await controller.initialize();

        final created = await controller.registerSyncAccount(
          username: 'alice',
          password: 'Motdepasse1!',
        );

        expect(created, isTrue);
        expect(auth.registeredUsernames, ['alice']);
        expect(auth.loggedInUsernames, ['alice']);
        expect(controller.errorMessage, isNull);

        await controller.completeSyncStep();
        expect(
          controller.progress.completedSteps.contains(
            OnboardingStep.syncChoice,
          ),
          isTrue,
        );
      },
    );

    test('registerSyncAccount rejects a too-short account password', () async {
      final auth = FakeAuthService();
      final controller = OnboardingFlowController(
        onboardingStorageService: InMemoryOnboardingStorageService(),
        vaultService: FakeVaultService(),
        biometricStorageService: FakeBiometricStorageService(),
        featureFlagsController: featureFlagsControllerWith(),
        authService: auth,
      );

      final created = await controller.registerSyncAccount(
        username: 'alice',
        password: 'court',
      );

      expect(created, isFalse);
      expect(auth.registeredUsernames, isEmpty);
      expect(controller.errorMessage, isNotNull);
    });

    test('registerSyncAccount surfaces the auth error message', () async {
      final auth = FakeAuthService()
        ..failure = const AuthException.usernameTaken();
      final controller = OnboardingFlowController(
        onboardingStorageService: InMemoryOnboardingStorageService(),
        vaultService: FakeVaultService(),
        biometricStorageService: FakeBiometricStorageService(),
        featureFlagsController: featureFlagsControllerWith(),
        authService: auth,
      );

      final created = await controller.registerSyncAccount(
        username: 'alice',
        password: 'Motdepasse1!',
      );

      expect(created, isFalse);
      expect(controller.errorMessage, "Ce nom d'utilisateur est déjà pris.");
      expect(auth.loggedInUsernames, isEmpty);
    });
  });
}
