import 'dart:typed_data';

import '../../../core/sync/crdt_ffi.dart';
import '../../../core/sync/drift_projector.dart';
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

  SyncEngine({
    required SyncApi api,
    required VaultDocStore store,
    required PendingDeltaStore pending,
    required CrdtFfi ffi,
    required VaultReprojector reprojector,
    required Uint8List vaultKey,
    int pushBatch = 100,
    int pullLimit = 500,
  }) : _api = api,
       _store = store,
       _pending = pending,
       _ffi = ffi,
       _reprojector = reprojector,
       _vaultKey = vaultKey,
       _pushBatch = pushBatch,
       _pullLimit = pullLimit;

  /// Un cycle complet : push puis pull.
  @override
  Future<void> sync() async {
    await push();
    await pull();
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
  Future<void> pull() async {
    while (true) {
      final state = await _loadOrEmpty();

      final DeltaPage page;
      try {
        page = await _api.pullDeltas(since: state.cursor, limit: _pullLimit);
      } on SyncException catch (e) {
        if (e.kind == SyncErrorKind.cursorGone) {
          await _resetFromSnapshot();
          continue;
        }
        rethrow;
      }

      if (page.deltas.isEmpty) return;

      var doc = state.doc;
      var cursor = state.cursor;
      for (final delta in page.deltas) {
        doc = _ffi.merge(doc, delta.payload);
        if (delta.seq > cursor) cursor = delta.seq;
      }
      await _applyMerged(state, doc, cursor);

      if (cursor >= page.latest) return; // rattrapé
    }
  }

  Future<void> _resetFromSnapshot() async {
    final snapshot = await _api.getSnapshot();
    final state = await _loadOrEmpty();
    if (snapshot == null) {
      // Curseur trop ancien mais aucun snapshot : repartir de zéro pour re-tirer
      // tout le log (il reste disponible).
      await _store.save(state.copyWith(cursor: 0));
      return;
    }
    // Le snapshot est un état complet, join-compatible : on le **fusionne** (sans
    // écraser d'éventuelles écritures locales non encore poussées).
    final doc = _ffi.merge(state.doc, snapshot.payload);
    await _applyMerged(state, doc, snapshot.coversSeq);
  }

  /// Persiste le doc fusionné + l'horloge **avancée au-delà du max reçu** + le
  /// curseur, puis reprojette en base. L'avancée d'horloge évite qu'une écriture
  /// locale ultérieure ne perde en LWW face à une valeur distante déjà fusionnée.
  Future<void> _applyMerged(
    VaultDocState state,
    Uint8List doc,
    int cursor,
  ) async {
    final clock = _maxTick(state.clock, _ffi.maxHlc(doc));
    await _store.save(state.copyWith(doc: doc, clock: clock, cursor: cursor));
    await _reprojector.reproject(doc, _vaultKey);
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
