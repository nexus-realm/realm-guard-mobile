import 'dart:async';

import 'package:flutter/widgets.dart';

import 'vault_service.dart';

/// Raison d'un verrouillage automatique du coffre, communiquée à l'utilisateur
/// via une snackbar lorsqu'il revient sur l'écran de déverrouillage.
enum LockReason {
  /// L'application est passée en arrière-plan.
  background,

  /// L'application est restée inactive trop longtemps.
  inactivity,
}

/// Verrouille automatiquement le coffre pour limiter la fenêtre d'exposition
/// d'une session déverrouillée :
///  - immédiatement quand l'application passe en arrière-plan
///    ([AppLifecycleState.paused] / [AppLifecycleState.detached]) ;
///  - après une période d'inactivité utilisateur ([_inactivityTimeout]).
///
/// Lors d'un verrouillage, le callback `onLock` fourni à [attach] est appelé
/// afin que l'appelant puisse renvoyer l'utilisateur vers l'écran de
/// déverrouillage. La raison du verrouillage est mémorisée et récupérable via
/// [takePendingMessage] pour en informer l'utilisateur.
class AppLockController with WidgetsBindingObserver {
  AppLockController({
    required VaultService vaultService,
    Duration inactivityTimeout = _defaultInactivityTimeout,
    Duration checkInterval = _defaultCheckInterval,
    DateTime Function() clock = DateTime.now,
  }) : _vaultService = vaultService,
       _inactivityTimeout = inactivityTimeout,
       _checkInterval = checkInterval,
       _clock = clock;

  // Délai d'inactivité avant verrouillage. Ajustable (futur réglage UI).
  static const Duration _defaultInactivityTimeout = Duration(minutes: 2);
  // Fréquence de vérification de l'inactivité (granularité du délai).
  static const Duration _defaultCheckInterval = Duration(seconds: 20);

  final VaultService _vaultService;
  final Duration _inactivityTimeout;
  final Duration _checkInterval;
  final DateTime Function() _clock;

  VoidCallback? _onLock;
  Timer? _ticker;
  DateTime _lastActivity = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wasUnlocked = false;
  LockReason? _pendingMessage;

  /// Démarre l'observation du cycle de vie et la surveillance de l'inactivité.
  /// [onLock] est appelé à chaque verrouillage automatique.
  void attach({required VoidCallback onLock}) {
    _onLock = onLock;
    _lastActivity = _clock();
    _wasUnlocked = _vaultService.isUnlocked;
    WidgetsBinding.instance.addObserver(this);
    _ticker ??= Timer.periodic(_checkInterval, (_) => evaluateInactivity());
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _ticker = null;
    _onLock = null;
  }

  /// Enregistre une activité utilisateur ; réinitialise le compte à rebours.
  void notifyInteraction() {
    _lastActivity = _clock();
  }

  /// Récupère — une seule fois — la raison du dernier verrouillage automatique,
  /// afin d'en informer l'utilisateur (snackbar). Retourne `null` si aucun
  /// message n'est en attente (déverrouillage normal ou message déjà consommé).
  LockReason? takePendingMessage() {
    final reason = _pendingMessage;
    _pendingMessage = null;
    return reason;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycleState(state);
  }

  @visibleForTesting
  void handleLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lock(LockReason.background);
    }
  }

  @visibleForTesting
  void evaluateInactivity() {
    final isUnlocked = _vaultService.isUnlocked;

    // Réinitialise l'horloge d'activité dès que le coffre devient déverrouillé
    // pour qu'un timestamp obsolète d'une session précédente ne déclenche pas
    // un verrouillage immédiat.
    if (isUnlocked && !_wasUnlocked) {
      _lastActivity = _clock();
    }
    _wasUnlocked = isUnlocked;

    if (!isUnlocked) return;

    if (_clock().difference(_lastActivity) >= _inactivityTimeout) {
      _lock(LockReason.inactivity);
    }
  }

  void _lock(LockReason reason) {
    if (!_vaultService.isUnlocked) return;
    _vaultService.lockVault();
    _wasUnlocked = false;
    _pendingMessage = reason;
    _onLock?.call();
  }
}
