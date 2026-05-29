import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'biometric_storage_service.dart';
import 'vault_service.dart';

enum UnlockAttemptResult { success, invalidPassword, biometricFailed, locked }

enum UnlockStrategy { biometric, password }

class UnlockService {
  final FlutterSecureStorage _secureStorage;
  final BiometricStorageService _biometricService;
  final VaultService _vaultService;

  // Clés de stockage
  static const String _lastKeyTimestampKey = 'last_key_timestamp_v1';
  static const String _lastBiometricPromptKey = 'last_biometric_prompt_v1';
  static const String _failedAttemptsCountKey = 'failed_attempts_count_v1';
  static const String _lockoutTimestampKey = 'lockout_timestamp_v1';
  static const String _biometricFailuresKey = 'biometric_failures_count_v1';
  static const String _lastFailedAttemptKey = 'last_failed_attempt_v1';

  // Configuration
  static const Duration _keyValidityDuration = Duration(days: 7);
  static const Duration _biometricPromptInterval = Duration(days: 7);
  static const Duration _defaultAttemptCooldown = Duration(seconds: 2);
  static const Duration _lockoutDuration = Duration(minutes: 5);
  static const int _maxFailedAttempts = 5;

  /// Durée sans tentative au bout de laquelle tout le suivi d'échecs (compteur,
  /// lockout, échecs biométriques) est réinitialisé. Doit rester strictement
  /// supérieure à [_lockoutDuration] pour préserver le re-lock immédiat tant que
  /// la fenêtre d'inactivité n'est pas écoulée.
  static const Duration _failedAttemptResetWindow = Duration(minutes: 15);

  final Duration _attemptCooldown;

  UnlockService({
    FlutterSecureStorage? secureStorage,
    BiometricStorageService? biometricService,
    VaultService? vaultService,
    Duration? attemptCooldown,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _biometricService = biometricService ?? BiometricStorageService(),
       _vaultService = vaultService ?? VaultService(),
       _attemptCooldown = attemptCooldown ?? _defaultAttemptCooldown;

  /// Détermine la stratégie de déverrouillage au lancement
  Future<UnlockStrategy> determineUnlockStrategy() async {
    // Réinitialise le suivi d'échecs si la fenêtre d'inactivité est écoulée.
    await _resetTrackingIfStale();

    // Vérifier si la clé biométrique existe et est valide
    final keyTimestamp = await _getKeyTimestamp();
    final isKeyExpired = _isKeyExpired(keyTimestamp);

    final lastBiometricPrompt = await _getLastBiometricPrompt();
    final shouldPromptBiometric = _shouldPromptBiometric(lastBiometricPrompt);

    final isBiometricAvailable = await _biometricService.isBiometricAvailable();
    final isBiometricEnabled = await _biometricService.isBiometricEnabled();
    final biometricFailures = await _getBiometricFailures();

    // Stratégie : essayer la biométrie si l'utilisateur l'a activée, que la clé
    // est valide et qu'il n'y a pas d'échecs récents
    if (!isKeyExpired &&
        isBiometricAvailable &&
        isBiometricEnabled &&
        biometricFailures < _maxFailedAttempts &&
        !shouldPromptBiometric) {
      return UnlockStrategy.biometric;
    }

    // Si clé expirée, biométrie désactivée, ou trop d'échecs -> mot de passe
    return UnlockStrategy.password;
  }

  /// Tentative de déverrouillage avec biométrie
  Future<(UnlockAttemptResult, bool)> attemptBiometricUnlock() async {
    // Réinitialise le suivi d'échecs si la fenêtre d'inactivité est écoulée.
    await _resetTrackingIfStale();

    // Vérifier le lockout
    if (await _isLockedOut()) {
      return (UnlockAttemptResult.locked, false);
    }

    try {
      await _checkAttemptCooldown();

      final status = await _vaultService.unlockWithBiometrics();

      switch (status) {
        case BiometricUnlockStatus.success:
          // Succès : réinitialiser les compteurs
          await _clearFailureTracking();
          await _updateLastBiometricPrompt();
          return (UnlockAttemptResult.success, true);
        case BiometricUnlockStatus.failed:
          // Échec biométrique réel : ne pénalise QUE le compteur biométrique,
          // jamais le verrouillage par mot de passe.
          await _incrementBiometricFailures();
          return (UnlockAttemptResult.biometricFailed, false);
        case BiometricUnlockStatus.canceled:
        case BiometricUnlockStatus.unavailable:
          // Annulation / indisponibilité : aucun compteur n'est touché.
          return (UnlockAttemptResult.biometricFailed, false);
      }
    } catch (e) {
      return (UnlockAttemptResult.biometricFailed, false);
    }
  }

  /// Tentative de déverrouillage avec mot de passe
  Future<(UnlockAttemptResult, bool)> attemptPasswordUnlock(
    String password,
  ) async {
    // Réinitialise le suivi d'échecs si la fenêtre d'inactivité est écoulée.
    await _resetTrackingIfStale();

    // Vérifier le lockout
    if (await _isLockedOut()) {
      return (UnlockAttemptResult.locked, false);
    }

    try {
      await _checkAttemptCooldown();

      await _vaultService.unlockWithMasterPassword(password);

      // Succès : réinitialiser les compteurs et mettre à jour timestamps
      await _clearFailureTracking();
      await _updateKeyTimestamp();
      await _updateLastBiometricPrompt();

      return (UnlockAttemptResult.success, true);
    } catch (e) {
      // Échec mot de passe
      await _recordFailedAttempt();

      // Vérifier si on atteint le lockout
      final isNowLocked = await _isLockedOut();

      return (UnlockAttemptResult.invalidPassword, isNowLocked);
    }
  }

  /// Récupère le temps restant avant déverrouillage (lockout)
  Future<Duration> getRemainingLockout() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutTimestampKey);
    if (lockoutStr == null) return Duration.zero;

    try {
      final lockoutTime = DateTime.parse(lockoutStr);
      final now = DateTime.now();

      if (now.isBefore(lockoutTime)) {
        return lockoutTime.difference(now);
      }

      // Lockout expiré
      await _secureStorage.delete(key: _lockoutTimestampKey);
      return Duration.zero;
    } catch (_) {
      // Format invalide, nettoyer
      await _secureStorage.delete(key: _lockoutTimestampKey);
      return Duration.zero;
    }
  }

  Future<void> _checkAttemptCooldown() async {
    // Implémentation simple : attendre entre tentatives si nécessaire
    await Future.delayed(_attemptCooldown);
  }

  Future<bool> _isLockedOut() async {
    final remaining = await getRemainingLockout();
    return remaining.inMilliseconds > 0;
  }

  Future<void> _recordFailedAttempt() async {
    final countStr = await _secureStorage.read(key: _failedAttemptsCountKey);
    final count = int.tryParse(countStr ?? '0') ?? 0;
    final newCount = count + 1;

    await _secureStorage.write(
      key: _failedAttemptsCountKey,
      value: newCount.toString(),
    );
    // Mémorise l'instant de la tentative pour la fenêtre de réinitialisation.
    await _secureStorage.write(
      key: _lastFailedAttemptKey,
      value: DateTime.now().toIso8601String(),
    );

    if (newCount >= _maxFailedAttempts) {
      // Engager le lockout (conservé : re-lock immédiat si on est déjà au max)
      final lockoutEnd = DateTime.now().add(_lockoutDuration);
      await _secureStorage.write(
        key: _lockoutTimestampKey,
        value: lockoutEnd.toIso8601String(),
      );
    }
  }

  Future<void> _clearFailureTracking() async {
    await _secureStorage.delete(key: _failedAttemptsCountKey);
    await _secureStorage.delete(key: _lockoutTimestampKey);
    await _secureStorage.delete(key: _biometricFailuresKey);
    await _secureStorage.delete(key: _lastFailedAttemptKey);
  }

  /// Réinitialise tout le suivi d'échecs si aucune tentative n'a eu lieu depuis
  /// [_failedAttemptResetWindow]. Redonne un quota complet de tentatives après
  /// une période d'inactivité, sans supprimer le re-lock immédiat tant que la
  /// fenêtre n'est pas écoulée.
  Future<void> _resetTrackingIfStale() async {
    final lastAttempt = await _getLastFailedAttempt();
    if (lastAttempt == null) return;
    if (DateTime.now().difference(lastAttempt) > _failedAttemptResetWindow) {
      await _clearFailureTracking();
    }
  }

  Future<DateTime?> _getLastFailedAttempt() async {
    final timestamp = await _secureStorage.read(key: _lastFailedAttemptKey);
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _getKeyTimestamp() async {
    final timestamp = await _secureStorage.read(key: _lastKeyTimestampKey);
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  bool _isKeyExpired(DateTime? timestamp) {
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > _keyValidityDuration;
  }

  Future<void> _updateKeyTimestamp() async {
    await _secureStorage.write(
      key: _lastKeyTimestampKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> _getLastBiometricPrompt() async {
    final timestamp = await _secureStorage.read(key: _lastBiometricPromptKey);
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  bool _shouldPromptBiometric(DateTime? lastPrompt) {
    if (lastPrompt == null) return true;
    return DateTime.now().difference(lastPrompt) > _biometricPromptInterval;
  }

  Future<void> _updateLastBiometricPrompt() async {
    await _secureStorage.write(
      key: _lastBiometricPromptKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<int> _getBiometricFailures() async {
    final countStr = await _secureStorage.read(key: _biometricFailuresKey);
    return int.tryParse(countStr ?? '0') ?? 0;
  }

  Future<void> _incrementBiometricFailures() async {
    final count = await _getBiometricFailures();
    await _secureStorage.write(
      key: _biometricFailuresKey,
      value: (count + 1).toString(),
    );
  }
}
