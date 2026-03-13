import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';
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

void main() {
  group('StartupGateViewModel', () {
    test('targets onboarding when flow is not completed', () async {
      final viewModel = StartupGateViewModel(
        onboardingStorageService: InMemoryOnboardingStorageService(
          OnboardingProgress.initial(),
        ),
      );

      await viewModel.initialize();

      expect(viewModel.targetRoute, StartupRouteTarget.onboarding);
      expect(viewModel.isLoading, isFalse);
    });

    test('targets home when flow is completed', () async {
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
      );

      await viewModel.initialize();

      expect(viewModel.targetRoute, StartupRouteTarget.home);
      expect(viewModel.isLoading, isFalse);
    });
  });
}
