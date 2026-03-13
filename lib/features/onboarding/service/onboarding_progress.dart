import '../data/onboarding_step.dart';

class OnboardingProgress {
  final Set<OnboardingStep> completedSteps;
  final bool? biometricEnabled;

  const OnboardingProgress({
    required this.completedSteps,
    this.biometricEnabled,
  });

  factory OnboardingProgress.initial() {
    return const OnboardingProgress(completedSteps: <OnboardingStep>{});
  }

  bool get isCompleted => completedSteps.length == OnboardingStep.values.length;

  OnboardingStep? get nextMissingStep {
    for (final step in OnboardingStep.values) {
      if (!completedSteps.contains(step)) {
        return step;
      }
    }
    return null;
  }

  OnboardingProgress markStepCompleted(
    OnboardingStep step, {
    bool? biometricEnabled,
  }) {
    final updatedSteps = Set<OnboardingStep>.from(completedSteps)..add(step);
    return OnboardingProgress(
      completedSteps: updatedSteps,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'completedSteps': completedSteps.map((step) => step.storageKey).toList(),
      'biometricEnabled': biometricEnabled,
    };
  }

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['completedSteps'];
    final completed = <OnboardingStep>{};

    if (rawSteps is List) {
      for (final rawStep in rawSteps) {
        if (rawStep is String) {
          final parsedStep = OnboardingStep.fromStorageKey(rawStep);
          if (parsedStep != null) {
            completed.add(parsedStep);
          }
        }
      }
    }

    return OnboardingProgress(
      completedSteps: completed,
      biometricEnabled:
          json['biometricEnabled'] is bool ? json['biometricEnabled'] as bool : null,
    );
  }
}

