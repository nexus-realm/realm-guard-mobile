import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'onboarding_progress.dart';

class OnboardingStorageService {
  final FlutterSecureStorage _secureStorage;

  static const String _onboardingProgressKey = 'onboarding_progress_v1';

  OnboardingStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<OnboardingProgress> loadProgress() async {
    final storedValue = await _secureStorage.read(key: _onboardingProgressKey);
    if (storedValue == null || storedValue.isEmpty) {
      return OnboardingProgress.initial();
    }

    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is Map<String, dynamic>) {
        return OnboardingProgress.fromJson(decoded);
      }
      if (decoded is Map) {
        return OnboardingProgress.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      await _secureStorage.delete(key: _onboardingProgressKey);
    }

    return OnboardingProgress.initial();
  }

  Future<void> saveProgress(OnboardingProgress progress) async {
    final encoded = jsonEncode(progress.toJson());
    await _secureStorage.write(key: _onboardingProgressKey, value: encoded);
  }

  Future<void> clearProgress() async {
    await _secureStorage.delete(key: _onboardingProgressKey);
  }
}
