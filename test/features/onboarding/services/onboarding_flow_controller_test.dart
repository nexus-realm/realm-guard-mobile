import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_flow_controller.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';

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
        OnboardingProgress.initial().markStepCompleted(
          OnboardingStep.welcome,
        ),
      );

      final controller = OnboardingFlowController(
        onboardingStorageService: storage,
        vaultService: FakeVaultService(),
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
      );

      await controller.initialize();
      await controller.completeWelcomeStep();

      final success = await controller.completeMasterPasswordStep(
        'motdepasse-solide',
        'motdepasse-solide',
      );

      expect(success, isTrue);
      expect(vault.lastPassword, 'motdepasse-solide');
      expect(vault.isLocked, isTrue);
      expect(
        controller.progress.completedSteps.contains(OnboardingStep.masterPassword),
        isTrue,
      );
    });

    test('clears biometric key when user refuses biometrics', () async {
      final storage = InMemoryOnboardingStorageService();
      final vault = FakeVaultService();
      final biometrics = FakeBiometricStorageService();

      final controller = OnboardingFlowController(
        onboardingStorageService: storage,
        vaultService: vault,
        biometricStorageService: biometrics,
      );

      await controller.initialize();
      await controller.completeWelcomeStep();
      await controller.completeMasterPasswordStep(
        'motdepasse-solide',
        'motdepasse-solide',
      );
      await controller.completeBiometricStep(false);

      expect(biometrics.clearWasCalled, isTrue);
      expect(controller.isCompleted, isTrue);
      expect(controller.progress.biometricEnabled, isFalse);
    });
  });
}


