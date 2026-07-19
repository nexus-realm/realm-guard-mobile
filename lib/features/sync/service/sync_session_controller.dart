import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../core/security/vault_service.dart';
import '../../../core/sync/crdt_ffi.dart';
import '../../../core/sync/drift_projector.dart';
import '../../../core/sync/pending_delta_store.dart';
import '../../../core/sync/vault_doc_store.dart';
import 'sync_api.dart';
import 'sync_controller.dart';
import 'sync_engine.dart';
import 'sync_socket.dart';

/// Gère le cycle de vie de la synchronisation d'une **session** déverrouillée :
/// construit et démarre la pile (engine + WS + contrôleur) au déverrouillage,
/// la coupe au verrouillage, et déclenche un cycle au retour au premier plan,
/// **après chaque écriture locale**, et **périodiquement** (filet).
///
/// Best-effort et non bloquant : rien ici ne doit perturber le coffre. Le doc
/// reste un artefact de synchro ; lectures et écritures passent par drift.
class SyncSessionController with WidgetsBindingObserver {
  final VaultService _vaultService;
  final SyncApi _api;
  final SyncSocket Function() _socketFactory;
  final CrdtFfi _ffi;
  final Duration _tickInterval;

  SyncController? _controller;
  Timer? _ticker;
  bool _attached = false;
  bool _starting = false;

  // Notifie l'UI après un tirage ayant modifié le coffre depuis un autre appareil
  // (notification passive). `count` = nb d'entrées changées du dernier tirage.
  final _RemoteChanges _remoteChanges = _RemoteChanges();

  /// S'abonner pour signaler à l'utilisateur une mise à jour reçue d'un autre
  /// appareil. Lire [lastRemoteChangeCount] à la notification.
  Listenable get onRemoteChange => _remoteChanges;

  /// Nombre d'entrées changées au dernier tirage distant.
  int get lastRemoteChangeCount => _remoteChanges.count;

  SyncSessionController({
    required VaultService vaultService,
    required SyncApi api,
    required SyncSocket Function() socketFactory,
    CrdtFfi ffi = const FrbCrdtFfi(),
    Duration tickInterval = const Duration(seconds: 30),
  }) : _vaultService = vaultService,
       _api = api,
       _socketFactory = socketFactory,
       _ffi = ffi,
       _tickInterval = tickInterval;

  /// Observe le cycle de vie de l'app et les mutations locales du coffre.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _vaultService.onLocalMutation.addListener(_onLocalMutation);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _vaultService.onLocalMutation.removeListener(_onLocalMutation);
    unawaited(stop());
  }

  /// Construit et démarre la pile pour la session courante si le coffre est
  /// déverrouillé et qu'elle ne tourne pas déjà. Idempotent, best-effort.
  Future<void> ensureStarted() async {
    if (_controller != null || _starting) return;
    if (!_vaultService.isUnlocked) return;
    final key = _vaultService.vaultKey;
    if (key == null) return;

    _starting = true;
    try {
      // Sème le doc depuis les lignes v1 existantes (idempotent) avant de pousser.
      // **Impératif de sûreté** : si le seed échoue, le doc peut être vide alors
      // que des lignes locales existent → un tirage suivant reprojetterait un doc
      // vide et **supprimerait ces lignes**. On ne démarre donc l'engine que si la
      // session CRDT (et donc le seed) a réussi ; sinon on réessaiera au prochain
      // déclencheur.
      final crdt = await _vaultService.ensureCrdtSession();
      if (crdt == null) return;

      final db = _vaultService.db;
      final engine = SyncEngine(
        api: _api,
        store: DriftVaultDocStore(db),
        pending: DriftPendingDeltaStore(db),
        ffi: _ffi,
        reprojector: DriftProjector(db, _ffi),
        vaultKey: Uint8List.fromList(key),
        // Verrou partagé avec VaultCrdt (créé par ensureCrdtSession) → sérialise
        // les tirages et les écritures locales sur le même doc.
        lock: _vaultService.docLock,
        // Notification passive : nb d'entrées modifiées par un tirage distant.
        onRemoteChange: _remoteChanges.report,
      );
      final controller = SyncController(
        engine: engine,
        socket: _socketFactory(),
      );
      _controller = controller;
      _ticker = Timer.periodic(
        _tickInterval,
        (_) => unawaited(controller.requestSync()),
      );
      await controller.start();
    } catch (_) {
      // Best-effort : on réessaiera au prochain déclencheur.
      await stop();
    } finally {
      _starting = false;
    }
  }

  /// Coupe la pile de synchro (au verrouillage / à la fermeture).
  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    final controller = _controller;
    _controller = null;
    await controller?.stop();
  }

  void _onLocalMutation() =>
      unawaited(_controller?.requestSync() ?? Future<void>.value());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
    // paused / detached : AppLockController verrouille le coffre → stop() via onLock.
  }

  Future<void> _onResumed() async {
    await ensureStarted();
    await _controller?.requestSync();
  }
}

/// Notifie ses abonnés qu'un tirage a modifié le coffre depuis un autre appareil.
/// Expose [report] car `notifyListeners` est protégé.
class _RemoteChanges extends ChangeNotifier {
  int count = 0;

  void report(int changedEntries) {
    count = changedEntries;
    notifyListeners();
  }
}
