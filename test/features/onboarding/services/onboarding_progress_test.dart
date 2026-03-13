import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/onboarding/service/onboarding_progress.dart';
import 'package:realm_guard_mobile/features/onboarding/data/onboarding_step.dart';

void main() {
  group('OnboardingProgress', () {
    test('returns first missing step from an empty progress', () {
      final progress = OnboardingProgress.initial();

      expect(progress.nextMissingStep, OnboardingStep.welcome);
      expect(progress.isCompleted, isFalse);
    });

    test('marks steps as completed in order', () {
      final step1 = OnboardingProgress.initial().markStepCompleted(
        OnboardingStep.welcome,
      );
      final step2 = step1.markStepCompleted(OnboardingStep.masterPassword);
      final step3 = step2.markStepCompleted(
        OnboardingStep.biometricChoice,
        biometricEnabled: true,
      );

      expect(step2.nextMissingStep, OnboardingStep.biometricChoice);
      expect(step3.nextMissingStep, isNull);
      expect(step3.isCompleted, isTrue);
      expect(step3.biometricEnabled, isTrue);
    });

    test('serializes and deserializes completed steps', () {
      final progress = OnboardingProgress(
        completedSteps: {
          OnboardingStep.welcome,
          OnboardingStep.masterPassword,
        },
        biometricEnabled: false,
      );

      final decoded = OnboardingProgress.fromJson(progress.toJson());

      expect(decoded.completedSteps, progress.completedSteps);
      expect(decoded.biometricEnabled, isFalse);
      expect(decoded.nextMissingStep, OnboardingStep.biometricChoice);
    });
  });
}

