import 'dart:async';

import 'sync_engine.dart';
import 'sync_socket.dart';

/// Coordonne la synchronisation d'une session : un cycle initial, puis un cycle à
/// chaque *nudge* WS et à chaque [requestSync] (retour au premier plan, après
/// écriture). Deux garde-fous :
///
/// - **Sérialisation / coalescence** : jamais deux cycles concurrents sur le même
///   coffre. Un déclencheur reçu pendant un cycle en cours programme **un seul**
///   cycle de rattrapage à la fin (les déclencheurs multiples fusionnent).
/// - **Best-effort** : toute erreur (réseau, session) est avalée — on retentera
///   au prochain déclencheur. La synchro ne doit jamais faire remonter d'erreur à
///   l'app.
class SyncController {
  final SyncRunner _engine;
  final SyncSocket _socket;

  StreamSubscription<void>? _nudges;
  bool _started = false;
  bool _running = false;
  bool _pending = false;

  SyncController({required SyncRunner engine, required SyncSocket socket})
    : _engine = engine,
      _socket = socket;

  /// Démarre : écoute les nudges, connecte le WS, et lance un cycle initial **en
  /// tâche de fond** (ne bloque pas l'appelant — p. ex. le déverrouillage — sur le
  /// réseau).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _nudges = _socket.nudges.listen((_) => unawaited(_run()));
    await _socket.connect();
    unawaited(_run());
  }

  /// Demande un cycle (fusionné avec un éventuel cycle en cours).
  Future<void> requestSync() => _run();

  /// Arrête : coupe l'écoute et ferme le WS.
  Future<void> stop() async {
    _started = false;
    await _nudges?.cancel();
    _nudges = null;
    await _socket.disconnect();
  }

  Future<void> _run() async {
    if (_running) {
      _pending = true; // un cycle tourne déjà → un seul rattrapage à la fin
      return;
    }
    _running = true;
    try {
      do {
        _pending = false;
        try {
          await _engine.sync();
        } catch (_) {
          // Best-effort : réseau/session indisponible → prochain déclencheur.
        }
      } while (_pending);
    } finally {
      _running = false;
    }
  }
}
