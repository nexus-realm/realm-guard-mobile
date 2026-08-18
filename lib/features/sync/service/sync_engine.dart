import 'dart:typed_data';

import '../../../core/sync/crdt_ffi.dart';
import '../../../core/sync/drift_projector.dart';
import '../../../core/sync/mutex.dart';
import '../../../core/sync/pending_delta_store.dart';
import '../../../core/sync/vault_doc_store.dart';
import '../data/sync_exception.dart';
import '../data/sync_models.dart';
import 'sync_api.dart';

/// Un cycle de synchronisation complet (push + pull). Abstrait pour que le
/// `SyncController` (d-5) se teste sans engine réel.
abstract interface class SyncRunner {
  Future<void> sync();
}

/// Orchestrateur de synchronisation : **pousse** les deltas locaux en attente et
/// **tire** ceux des autres appareils depuis le curseur, en fusionnant dans le
/// doc puis en reprojetant en base. Le doc reste la source de vérité ; drift est
/// la projection lisible.
///
/// À déclencher au déverrouillage, au retour au premier plan, et sur *nudge* WS
/// (d-5). Suppose un appel sérialisé (pas de sync concurrente sur le même coffre).
class SyncEngine implements SyncRunner {
  final SyncApi _api;
  final VaultDocStore _store;
  final PendingDeltaStore _pending;
  final CrdtFfi _ffi;
  final VaultReprojector _reprojector;
  final Uint8List _vaultKey;
  final int _pushBatch;
  final int _pullLimit;
  final Mutex _lock;
  final int _snapshotThreshold;
  final void Function(int changedEntries)? _onRemoteChange;

  // Dernier `covers_seq` pour lequel **cet appareil** a publié un snapshot (en
  // mémoire, par session) : borne la fréquence de compaction.
  int _lastSnapshotCursor = 0;

  SyncEngine({
    required SyncApi api,
    required VaultDocStore store,
    required PendingDeltaStore pending,
    required CrdtFfi ffi,
    required VaultReprojector reprojector,
    required Uint8List vaultKey,
    int pushBatch = 100,
    int pullLimit = 500,
    Mutex? lock,
    int snapshotThreshold = 200,
    void Function(int changedEntries)? onRemoteChange,
  }) : _api = api,
       _store = store,
       _pending = pending,
       _ffi = ffi,
       _reprojector = reprojector,
       _vaultKey = vaultKey,
       _pushBatch = pushBatch,
       _pullLimit = pullLimit,
       _snapshotThreshold = snapshotThreshold,
       _onRemoteChange = onRemoteChange,
       // Verrou partagé (par session) avec `VaultCrdt` — sérialise les RMW du doc.
       _lock = lock ?? Mutex();

  /// Un cycle complet : push, pull, puis compaction éventuelle par snapshot.
  /// Signale via `onRemoteChange` le nombre d'entrées **réellement** modifiées
  /// par le tirage (pour une notification passive à l'utilisateur).
  @override
  Future<void> sync() async {
    await push();
    final changed = await pull();
    await _maybeSnapshot();
    if (changed > 0) _onRemoteChange?.call(changed);
  }

  /// Draine la file de deltas locaux vers le serveur (FIFO, `ack` au fil de l'eau
  /// pour ne pas re-pousser en cas d'échec en milieu de lot).
  Future<void> push() async {
    while (true) {
      final batch = await _pending.peek(_pushBatch);
      if (batch.isEmpty) return;
      for (final delta in batch) {
        await _api.pushDelta(delta.payload);
        await _pending.ack([delta.id]);
      }
    }
  }

  /// Tire et applique les deltas distants jusqu'à rattraper le log. Sur **410**
  /// (curseur antérieur au snapshot), repart du snapshot.
  /// Renvoie le nombre total d'entrées **réellement** modifiées par le tirage.
  Future<int> pull() async {
    var total = 0;
    while (true) {
      // Curseur de départ (hors verrou) : sert au paramètre réseau `since`.
      final since = (await _loadOrEmpty()).cursor;

      final DeltaPage page;
      try {
        page = await _api.pullDeltas(since: since, limit: _pullLimit);
      } on SyncException catch (e) {
        if (e.kind == SyncErrorKind.cursorGone) {
          total += await _resetFromSnapshot();
          continue;
        }
        rethrow;
      }

      if (page.deltas.isEmpty) return total;

      // Section critique : rechargement **frais** du doc (une écriture locale a
      // pu tomber pendant l'attente réseau), merge, sauvegarde et reprojection —
      // atomiques vis-à-vis des écritures locales grâce au verrou partagé.
      final result = await _lock.run(() async {
        final state = await _loadOrEmpty();
        var doc = state.doc;
        var cursor = state.cursor;
        for (final delta in page.deltas) {
          doc = _ffi.merge(doc, delta.payload);
          if (delta.seq > cursor) cursor = delta.seq;
        }
        final changed = await _applyMerged(state, doc, cursor);
        return (caughtUp: cursor >= page.latest, changed: changed);
      });

      total += result.changed;
      if (result.caughtUp) return total; // rattrapé
    }
  }

  Future<int> _resetFromSnapshot() async {
    final snapshot = await _api.getSnapshot(); // réseau, hors verrou
    return _lock.run(() async {
      final state = await _loadOrEmpty();
      if (snapshot == null) {
        // Curseur trop ancien mais aucun snapshot : repartir de zéro pour re-tirer
        // tout le log (il reste disponible).
        await _store.save(state.copyWith(cursor: 0));
        return 0;
      }
      // Le snapshot est un état complet, join-compatible : on le **fusionne** (sans
      // écraser d'éventuelles écritures locales non encore poussées).
      final doc = _ffi.merge(state.doc, snapshot.payload);
      return _applyMerged(state, doc, snapshot.coversSeq);
    });
  }

  /// Publie un snapshot du doc courant (**compaction** du log serveur) si le
  /// curseur a assez avancé depuis le dernier snapshot de cet appareil. Le doc
  /// couvre `covers_seq = cursor` : il inclut tous les deltas ≤ cursor (un pair en
  /// retard tombera sur **410** et repartira de ce snapshot). Best-effort — un 409
  /// (un autre appareil a déjà compacté plus loin) ou une erreur réseau sont sans
  /// conséquence.
  Future<void> _maybeSnapshot() async {
    // Lecture cohérente (doc + curseur) sous le verrou ; l'envoi réseau reste dehors.
    final state = await _lock.run(() => _store.load());
    if (state == null) return;
    if (state.cursor - _lastSnapshotCursor < _snapshotThreshold) return;
    try {
      await _api.putSnapshot(state.doc, coversSeq: state.cursor);
      _lastSnapshotCursor = state.cursor;
    } on SyncException {
      // Compaction opportuniste : on retentera au prochain cycle.
    }
  }

  /// Persiste le doc fusionné + l'horloge **avancée au-delà du max reçu** + le
  /// curseur, puis reprojette en base. L'avancée d'horloge évite qu'une écriture
  /// locale ultérieure ne perde en LWW face à une valeur distante déjà fusionnée.
  Future<int> _applyMerged(
    VaultDocState state,
    Uint8List doc,
    int cursor,
  ) async {
    final clock = _maxTick(state.clock, _ffi.maxHlc(doc));
    await _store.save(state.copyWith(doc: doc, clock: clock, cursor: cursor));
    final summary = await _reprojector.reproject(doc, _vaultKey);
    return summary.changed;
  }

  Future<VaultDocState> _loadOrEmpty() async =>
      await _store.load() ??
      VaultDocState(
        doc: _ffi.newDoc(),
        clock: HlcTick(wallMs: BigInt.zero, counter: 0),
      );

  /// Le plus grand de deux HLC (mur puis compteur).
  HlcTick _maxTick(HlcTick a, HlcTick b) {
    if (a.wallMs != b.wallMs) return a.wallMs > b.wallMs ? a : b;
    return a.counter >= b.counter ? a : b;
  }
}
