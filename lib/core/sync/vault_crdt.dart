import 'dart:typed_data';

import 'crdt_ffi.dart';
import 'field_value.dart';
import 'mutex.dart';
import 'pending_delta_store.dart';
import 'vault_doc_store.dart';
import 'vault_projection.dart';

/// Une entrée à semer : son identité stable et sa carte de champs déjà encodée.
class SeedEntry {
  final Uint8List entryId;
  final Map<int, FieldValue> fields;

  const SeedEntry({required this.entryId, required this.fields});
}

/// Écriture **write-through** du coffre dans le CRDT : chaque mutation locale met
/// à jour le `VaultDoc` persisté (source de vérité de la synchro) en plus de la
/// base drift (assurée par l'appelant). Renvoie les deltas produits, à pousser au
/// serveur (P3.3d) ; le doc reste consultable localement via drift (projection).
///
/// `vaultKey` et `deviceId` sont des constantes de session/appareil ; `now`
/// fournit le temps physique (injectable en test).
class VaultCrdt {
  final CrdtFfi _ffi;
  final VaultDocStore _store;
  final PendingDeltaStore _pending;
  final VaultDocWriter _writer;
  final Uint8List _vaultKey;
  final Uint8List _deviceId;
  final DateTime Function() _now;
  final void Function()? _onChanged;
  final Mutex _lock;
  // Enveloppe transactionnelle (par session) rendant **atomiques** la sauvegarde
  // du doc et l'enfilement des deltas ; à défaut, exécution directe (non atomique,
  // suffisant en test).
  final Future<void> Function(Future<void> Function())? _transaction;

  VaultCrdt({
    required CrdtFfi ffi,
    required VaultDocStore store,
    required PendingDeltaStore pending,
    required Uint8List vaultKey,
    required Uint8List deviceId,
    DateTime Function() now = DateTime.now,
    void Function()? onChanged,
    Mutex? lock,
    Future<void> Function(Future<void> Function())? transaction,
  }) : _ffi = ffi,
       _store = store,
       _pending = pending,
       _writer = VaultDocWriter(ffi),
       _vaultKey = vaultKey,
       _deviceId = deviceId,
       _now = now,
       _onChanged = onChanged,
       _transaction = transaction,
       // Verrou partagé (par session) pour sérialiser les RMW du doc avec le
       // moteur de sync ; à défaut, un verrou propre (sérialise au moins soi-même).
       _lock = lock ?? Mutex();

  /// Exécute [action] dans la transaction fournie (atomique) ou directement.
  Future<void> _atomically(Future<void> Function() action) =>
      _transaction == null ? action() : _transaction(action);

  /// Applique une entrée (création si [isNew], sinon mise à jour) : chiffre et
  /// écrit ses [fields] dans le doc persisté. Renvoie les deltas produits.
  Future<List<Uint8List>> putEntry({
    required Uint8List entryId,
    required Map<int, FieldValue> fields,
    required bool isNew,
  }) async {
    final deltas = await _lock.run(() async {
      final state = await _loadOrEmpty();
      final result = _writer.putFields(
        doc: state.doc,
        entryId: entryId,
        deviceId: _deviceId,
        vaultKey: _vaultKey,
        fields: fields,
        clock: state.clock,
        nowMs: _nowMs(),
        markPresent: isNew,
      );
      // Atomique : doc sauvegardé **et** deltas enfilés, ou rien (pas de delta
      // orphelin). Curseur préservé : une écriture locale ne change pas la
      // progression de tirage.
      await _atomically(() async {
        await _store.save(state.copyWith(doc: result.doc, clock: result.clock));
        await _enqueue(result.deltas);
      });
      return result.deltas;
    });
    _onChanged?.call();
    return deltas;
  }

  /// Retire une entrée du coffre (tombstone add-wins). Renvoie le delta produit,
  /// ou vide si le coffre CRDT n'existe pas encore.
  Future<List<Uint8List>> removeEntry(Uint8List entryId) async {
    final deltas = await _lock.run(() async {
      final state = await _store.load();
      if (state == null) return const <Uint8List>[];
      final mutation = _ffi.removeEntry(state.doc, entryId);
      // La suppression n'émet pas d'HLC de champ : horloge et curseur conservés.
      await _atomically(() async {
        await _store.save(state.copyWith(doc: mutation.doc));
        await _enqueue([mutation.delta]);
      });
      return [mutation.delta];
    });
    if (deltas.isNotEmpty) _onChanged?.call();
    return deltas;
  }

  /// Sème un doc **neuf** à partir des [entries] existantes (migration v1→doc).
  /// Construit tout en mémoire puis persiste une seule fois. À n'appeler que
  /// lorsque le coffre CRDT n'existe pas encore.
  Future<void> seed(List<SeedEntry> entries) async {
    await _lock.run(() async {
      var state = _empty();
      final now = _nowMs();
      final deltas = <Uint8List>[];
      for (final entry in entries) {
        final result = _writer.putFields(
          doc: state.doc,
          entryId: entry.entryId,
          deviceId: _deviceId,
          vaultKey: _vaultKey,
          fields: entry.fields,
          clock: state.clock,
          nowMs: now,
          markPresent: true,
        );
        state = VaultDocState(doc: result.doc, clock: result.clock);
        deltas.addAll(result.deltas);
      }
      final built = state;
      await _atomically(() async {
        await _store.save(built);
        await _enqueue(deltas);
      });
    });
    _onChanged?.call();
  }

  Future<void> _enqueue(List<Uint8List> deltas) async {
    for (final delta in deltas) {
      await _pending.enqueue(delta);
    }
  }

  Future<VaultDocState> _loadOrEmpty() async => await _store.load() ?? _empty();

  VaultDocState _empty() => VaultDocState(
    doc: _ffi.newDoc(),
    clock: HlcTick(wallMs: BigInt.zero, counter: 0),
  );

  BigInt _nowMs() => BigInt.from(_now().millisecondsSinceEpoch);
}
