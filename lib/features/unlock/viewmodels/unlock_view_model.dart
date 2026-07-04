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
  DateTime? _lockoutEndsAt;
  final Duration _lockoutTick;
  int _biometricAttemptCount =
      0; // Compteur de tentatives biométriques dans cette session

  // Message générique : on n'expose jamais les détails internes d'une erreur.
  static const String _genericErrorMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  UnlockViewModel({
    required UnlockService unlockService,
    Duration lockoutTick = const Duration(seconds: 1),
  }) : _unlockService = unlockService,
       _lockoutTick = lockoutTick;

  UnlockStrategy? get strategy => _strategy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnlocked => _isUnlocked;
  Duration? get remainingLockout => _remainingLockout;
  int get biometricAttemptCount => _biometricAttemptCount;

  /// Temps de lockout restant formaté en `mm:ss` (ex: `04:30`), ou `null`
  /// si aucun lockout n'est actif.
  String? get remainingLockoutLabel {
    final remaining = _remainingLockout;
    if (remaining == null || remaining <= Duration.zero) return null;
    return formatLockout(remaining);
  }

  /// Formate une [Duration] en `mm:ss`. Les secondes sont arrondies au
  /// supérieur pour ne pas afficher `00:00` tant qu'il reste du temps.
  static String formatLockout(Duration duration) {
    final totalSeconds = duration.inMilliseconds <= 0
        ? 0
        : (duration.inMilliseconds / 1000).ceil();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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
        if (_biometricAttemptCount >= UnlockService.maxBiometricAttempts) {
          _strategy = UnlockStrategy.password;
          _errorMessage = null; // Effacer le message pour éviter la snackbar
        }
      }
    } catch (_) {
      _biometricAttemptCount++;
      _errorMessage = _genericErrorMessage;

      if (_biometricAttemptCount >= UnlockService.maxBiometricAttempts) {
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
    } catch (_) {
      _errorMessage = _genericErrorMessage;
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

    final remaining = _remainingLockout;
    if (remaining == null || remaining <= Duration.zero) {
      return;
    }

    // On calcule l'instant de fin UNE fois, puis on décompte en mémoire : plus
    // aucun accès au secure storage (platform channel) à chaque tick.
    _lockoutEndsAt = DateTime.now().add(remaining);
    _lockoutTimer = Timer.periodic(_lockoutTick, (_) {
      final left = _lockoutEndsAt!.difference(DateTime.now());
      _remainingLockout = left > Duration.zero ? left : Duration.zero;
      notifyListeners();
      if (_remainingLockout! <= Duration.zero) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
        _lockoutEndsAt = null;
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
