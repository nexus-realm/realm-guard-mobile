import 'dart:typed_data';

import 'crdt_ffi.dart';
import 'field_value.dart';
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
  final VaultDocWriter _writer;
  final Uint8List _vaultKey;
  final Uint8List _deviceId;
  final DateTime Function() _now;

  VaultCrdt({
    required CrdtFfi ffi,
    required VaultDocStore store,
    required Uint8List vaultKey,
    required Uint8List deviceId,
    DateTime Function() now = DateTime.now,
  }) : _ffi = ffi,
       _store = store,
       _writer = VaultDocWriter(ffi),
       _vaultKey = vaultKey,
       _deviceId = deviceId,
       _now = now;

  /// Applique une entrée (création si [isNew], sinon mise à jour) : chiffre et
  /// écrit ses [fields] dans le doc persisté. Renvoie les deltas produits.
  Future<List<Uint8List>> putEntry({
    required Uint8List entryId,
    required Map<int, FieldValue> fields,
    required bool isNew,
  }) async {
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
    await _store.save(VaultDocState(doc: result.doc, clock: result.clock));
    return result.deltas;
  }

  /// Retire une entrée du coffre (tombstone add-wins). Renvoie le delta produit,
  /// ou vide si le coffre CRDT n'existe pas encore.
  Future<List<Uint8List>> removeEntry(Uint8List entryId) async {
    final state = await _store.load();
    if (state == null) return const [];
    final mutation = _ffi.removeEntry(state.doc, entryId);
    // La suppression n'émet pas d'HLC de champ : l'horloge est conservée.
    await _store.save(VaultDocState(doc: mutation.doc, clock: state.clock));
    return [mutation.delta];
  }

  /// Sème un doc **neuf** à partir des [entries] existantes (migration v1→doc).
  /// Construit tout en mémoire puis persiste une seule fois. À n'appeler que
  /// lorsque le coffre CRDT n'existe pas encore.
  Future<void> seed(List<SeedEntry> entries) async {
    var state = _empty();
    final now = _nowMs();
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
    }
    await _store.save(state);
  }

  Future<VaultDocState> _loadOrEmpty() async => await _store.load() ?? _empty();

  VaultDocState _empty() => VaultDocState(
    doc: _ffi.newDoc(),
    clock: HlcTick(wallMs: BigInt.zero, counter: 0),
  );

  BigInt _nowMs() => BigInt.from(_now().millisecondsSinceEpoch);
}
