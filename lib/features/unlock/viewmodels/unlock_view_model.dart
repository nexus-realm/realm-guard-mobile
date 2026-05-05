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
  int _biometricAttemptCount =
      0; // Compteur de tentatives biométriques dans cette session

  UnlockViewModel({required UnlockService unlockService})
    : _unlockService = unlockService;

  UnlockStrategy? get strategy => _strategy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnlocked => _isUnlocked;
  Duration? get remainingLockout => _remainingLockout;
  int get biometricAttemptCount => _biometricAttemptCount;

  Future<void> initialize() async {
    _strategy = await _unlockService.determineUnlockStrategy();
    await _updateRemainingLockout();

    if (_remainingLockout != null && _remainingLockout!.inSeconds > 0) {
      _startLockoutTimer();
    }

    notifyListeners();

    if (_strategy == UnlockStrategy.biometric) {
      await attemptBiometric();
    }
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
        _biometricAttemptCount++;
        _errorMessage = _getErrorMessage(result);

        // Après plusieurs échecs biométriques, passer au mot de passe
        if (_biometricAttemptCount >= 3) {
          _strategy = UnlockStrategy.password;
          _errorMessage = null; // Effacer le message pour éviter la snackbar
        }
      }
    } catch (e) {
      _biometricAttemptCount++;
      _errorMessage = 'Erreur: ${e.toString()}';

      if (_biometricAttemptCount >= 3) {
        _strategy = UnlockStrategy.password;
        _errorMessage = null; // Effacer le message pour éviter la snackbar
      }
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

  void resetBiometricAttempts() {
    _biometricAttemptCount = 0;
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
