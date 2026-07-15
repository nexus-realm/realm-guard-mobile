import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart';
import 'package:realmguard/features/onboarding/data/onboarding_step.dart';

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
      final step2 = step1.markStepCompleted(OnboardingStep.syncChoice);
      final step3 = step2.markStepCompleted(OnboardingStep.masterPassword);
      final step4 = step3.markStepCompleted(
        OnboardingStep.biometricChoice,
        biometricEnabled: true,
      );
      final step5 = step4.markStepCompleted(OnboardingStep.totpChoice);

      expect(step1.nextMissingStep, OnboardingStep.syncChoice);
      expect(step2.nextMissingStep, OnboardingStep.masterPassword);
      expect(step3.nextMissingStep, OnboardingStep.biometricChoice);
      expect(step4.nextMissingStep, OnboardingStep.totpChoice);
      expect(step5.nextMissingStep, isNull);
      expect(step5.isCompleted, isTrue);
      expect(step5.biometricEnabled, isTrue);
    });

    test('serializes and deserializes completed steps', () {
      final progress = const OnboardingProgress(
        completedSteps: {OnboardingStep.welcome, OnboardingStep.masterPassword},
        biometricEnabled: false,
      );

      final decoded = OnboardingProgress.fromJson(progress.toJson());

      expect(decoded.completedSteps, progress.completedSteps);
      expect(decoded.biometricEnabled, isFalse);
      expect(decoded.nextMissingStep, OnboardingStep.syncChoice);
    });

    test('computes completion on a reduced set of active steps', () {
      final progress = OnboardingProgress.initial()
          .markStepCompleted(OnboardingStep.welcome)
          .markStepCompleted(OnboardingStep.masterPassword)
          .markStepCompleted(OnboardingStep.totpChoice)
          .markStepCompleted(OnboardingStep.syncChoice);
      final activeSteps = OnboardingStep.values
          .where((step) => step != OnboardingStep.biometricChoice)
          .toList(growable: false);

      expect(progress.isCompletedFor(activeSteps), isTrue);
      expect(progress.nextMissingStepFor(activeSteps), isNull);
      expect(progress.isCompleted, isFalse);
      expect(progress.nextMissingStep, OnboardingStep.biometricChoice);
    });
  });

  group('OnboardingProgress.withMigratedSteps', () {
    test('marks preference steps done for an already-installed user', () {
      final existing = OnboardingProgress.initial()
          .markStepCompleted(OnboardingStep.welcome)
          .markStepCompleted(OnboardingStep.masterPassword)
          .markStepCompleted(OnboardingStep.biometricChoice);

      final migrated = existing.withMigratedSteps();

      expect(
        migrated.completedSteps.contains(OnboardingStep.totpChoice),
        isTrue,
      );
      expect(
        migrated.completedSteps.contains(OnboardingStep.syncChoice),
        isTrue,
      );
      expect(migrated.isCompleted, isTrue);
    });

    test('leaves a new user untouched (master password not set yet)', () {
      final fresh = OnboardingProgress.initial().markStepCompleted(
        OnboardingStep.welcome,
      );

      final migrated = fresh.withMigratedSteps();

      expect(
        migrated.completedSteps.contains(OnboardingStep.totpChoice),
        isFalse,
      );
      expect(migrated.nextMissingStep, OnboardingStep.syncChoice);
    });
  });
}
