import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realm_guard_mobile/features/onboarding/viewmodels/startup_gate_view_model.dart';

class InMemoryOnboardingStorageService extends OnboardingStorageService {
  OnboardingProgress _progress;

  InMemoryOnboardingStorageService(this._progress);

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

class FakeBiometricStorageService extends BiometricStorageService {
  bool isAvailable = true;

  @override
  Future<bool> isBiometricAvailable() async {
    return isAvailable;
  }
}

void main() {
  group('StartupGateViewModel', () {
    test('targets onboarding when flow is not completed', () async {
      final viewModel = StartupGateViewModel(
        onboardingStorageService: InMemoryOnboardingStorageService(
          OnboardingProgress.initial(),
        ),
        biometricStorageService: FakeBiometricStorageService(),
      );

      await viewModel.initialize();

      expect(viewModel.targetRoute, StartupRouteTarget.onboarding);
      expect(viewModel.isLoading, isFalse);
    });

    test('targets unlock when flow is completed', () async {
      final completedProgress = OnboardingProgress.initial()
          .markStepCompleted(OnboardingStep.welcome)
          .markStepCompleted(OnboardingStep.masterPassword)
          .markStepCompleted(
            OnboardingStep.biometricChoice,
            biometricEnabled: true,
          );

      final viewModel = StartupGateViewModel(
        onboardingStorageService: InMemoryOnboardingStorageService(
          completedProgress,
        ),
        biometricStorageService: FakeBiometricStorageService(),
      );

      await viewModel.initialize();

      expect(viewModel.targetRoute, StartupRouteTarget.unlock);
      expect(viewModel.isLoading, isFalse);
    });

    test(
      'migrates an already-onboarded user (no TOTP step) to unlock',
      () async {
        // Utilisateur installé avant l'ajout de l'étape TOTP : anciennes étapes
        // terminées, mais `totpChoice` absent. Il ne doit pas être renvoyé dans
        // l'onboarding.
        final legacyProgress = OnboardingProgress.initial()
            .markStepCompleted(OnboardingStep.welcome)
            .markStepCompleted(OnboardingStep.masterPassword)
            .markStepCompleted(
              OnboardingStep.biometricChoice,
              biometricEnabled: true,
            );

        final viewModel = StartupGateViewModel(
          onboardingStorageService: InMemoryOnboardingStorageService(
            legacyProgress,
          ),
          biometricStorageService: FakeBiometricStorageService(),
        );

        await viewModel.initialize();

        expect(viewModel.targetRoute, StartupRouteTarget.unlock);
      },
    );

    test(
      'targets unlock without biometric completion when biometrics are unavailable',
      () async {
        final progressWithoutBiometric = OnboardingProgress.initial()
            .markStepCompleted(OnboardingStep.welcome)
            .markStepCompleted(OnboardingStep.masterPassword);
        final biometrics = FakeBiometricStorageService()..isAvailable = false;

        final viewModel = StartupGateViewModel(
          onboardingStorageService: InMemoryOnboardingStorageService(
            progressWithoutBiometric,
          ),
          biometricStorageService: biometrics,
        );

        await viewModel.initialize();

        expect(viewModel.targetRoute, StartupRouteTarget.unlock);
        expect(viewModel.isLoading, isFalse);
      },
    );
  });
}
