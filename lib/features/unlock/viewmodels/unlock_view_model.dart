import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/security/unlock_service.dart';

class UnlockViewModel extends ChangeNotifier {
  final UnlockService _unlockService;

  UnlockStrategy? _strategy;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnlocked = false;
  Duration? _remainingLockout;
  Timer? _lockoutTimer;

  UnlockViewModel({required UnlockService unlockService})
    : _unlockService = unlockService;

  UnlockStrategy? get strategy => _strategy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnlocked => _isUnlocked;
  Duration? get remainingLockout => _remainingLockout;

  Future<void> initialize() async {
    _strategy = await _unlockService.determineUnlockStrategy();
    await _updateRemainingLockout();
    notifyListeners();
  }

  Future<void> attemptBiometric() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final (result, success) = await _unlockService.attemptBiometricUnlock();

      if (success) {
        _isUnlocked = true;
      } else {
        _errorMessage = _getErrorMessage(result);
        if (result == UnlockAttemptResult.biometricFailed) {
          // Passer au mot de passe après un certain nombre d'échecs
          _strategy = UnlockStrategy.password;
        }
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> attemptPassword(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final (result, isNowLocked) = await _unlockService.attemptPasswordUnlock(
        password,
      );

      if (result == UnlockAttemptResult.success) {
        _isUnlocked = true;
      } else {
        _errorMessage = _getErrorMessage(result);
        if (isNowLocked) {
          notifyListeners(); // Afficher l'erreur immédiatement
          _errorMessage = null; // Effacer pour éviter les répétitions
          await _updateRemainingLockout();
          _startLockoutTimer();
        }
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchToPassword() {
    _strategy = UnlockStrategy.password;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _updateRemainingLockout() async {
    _remainingLockout = await _unlockService.getRemainingLockout();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _updateRemainingLockout();
      notifyListeners();
      if (_remainingLockout == null || _remainingLockout!.inSeconds <= 0) {
        _lockoutTimer?.cancel();
      }
    });
  }

  String _getErrorMessage(UnlockAttemptResult result) {
    return switch (result) {
      UnlockAttemptResult.invalidPassword => 'Mot de passe incorrect',
      UnlockAttemptResult.biometricFailed =>
        'Authentification biométrique échouée',
      UnlockAttemptResult.locked => 'Trop de tentatives. Réessayez plus tard.',
      UnlockAttemptResult.success => '',
    };
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
