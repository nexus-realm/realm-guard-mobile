import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';
import 'package:realm_guard_mobile/features/onboarding/viewmodels/onboarding_view_model.dart';

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
  @override
  Future<void> unlockWithMasterPassword(String masterPassword) async {}
}

OnboardingViewModel _buildViewModel() => OnboardingViewModel(
  onboardingStorageService: InMemoryOnboardingStorageService(),
  vaultService: FakeVaultService(),
  featureFlagsController: featureFlagsControllerWith(),
);

void main() {
  group('OnboardingViewModel', () {
    test('returns validation error for empty master password fields', () async {
      final viewModel = _buildViewModel();

      await viewModel.initialize();
      await viewModel.completeWelcomeStep();

      final success = await viewModel.completeMasterPasswordStep('', '');

      expect(success, isFalse);
      expect(viewModel.errorMessage, isNotNull);
      viewModel.dispose();
    });

    test('completes onboarding flow with valid inputs', () async {
      final viewModel = _buildViewModel();

      await viewModel.initialize();
      await viewModel.completeWelcomeStep();

      final success = await viewModel.completeMasterPasswordStep(
        'Motdepasse1!',
        'Motdepasse1!',
      );
      await viewModel.completeBiometricStep(true);
      await viewModel.completeTotpChoiceStep(true);

      expect(success, isTrue);
      expect(viewModel.currentStep, isNull);
      expect(viewModel.isCompleted, isTrue);
      viewModel.dispose();
    });

    test('starts at welcome step after initialization', () async {
      final viewModel = _buildViewModel();

      await viewModel.initialize();

      expect(viewModel.currentStep, OnboardingStep.welcome);
      viewModel.dispose();
    });
  });
}
