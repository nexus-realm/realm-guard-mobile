import 'dart:typed_data';

import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/drift_projector.dart';
import 'package:realmguard/core/sync/pending_delta_store.dart';
import 'package:realmguard/core/sync/vault_doc_store.dart';

/// Un appel enregistré à `setField`.
typedef SetFieldCall = ({
  Uint8List entryId,
  int fieldId,
  Uint8List value,
  BigInt wallMs,
  int counter,
});

/// Faux FFI CRDT sans lib native : le (dé)chiffrement est l'**identité** (le
/// « Ciphertext » est le clair encodé), l'HLC suit la règle du cœur
/// (`next_local`), et les mutations enregistrent leurs appels.
class FakeCrdtFfi implements CrdtFfi {
  /// Scénario de lecture (projection).
  final List<Uint8List> ids;
  final Map<String, List<CrdtField>> fieldsById;

  /// Doc « vide » renvoyé par [newDoc].
  final Uint8List emptyDoc;

  /// Enregistrements d'écriture.
  final List<SetFieldCall> setFields = [];
  final List<Uint8List> added = [];
  final List<Uint8List> removed = [];
  final List<Uint8List> merged = [];

  /// Valeur renvoyée par [maxHlc] (configurable pour l'avancée d'horloge).
  HlcTick maxHlcValue = HlcTick(wallMs: BigInt.zero, counter: 0);

  FakeCrdtFfi({
    this.ids = const [],
    this.fieldsById = const {},
    Uint8List? emptyDoc,
  }) : emptyDoc = emptyDoc ?? Uint8List.fromList([0]);

  static String hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  Uint8List newDoc() => emptyDoc;

  @override
  List<Uint8List> entryIds(Uint8List doc) => ids;

  @override
  List<CrdtField> entryFields(Uint8List doc, Uint8List entryId) =>
      fieldsById[hex(entryId)] ?? const [];

  @override
  Uint8List decryptField(Uint8List vaultKey, Uint8List entryId, Uint8List value) =>
      value;

  @override
  Uint8List encryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List plaintext,
  ) => plaintext;

  @override
  CrdtMutation addEntry(Uint8List doc, Uint8List entryId, Uint8List deviceId) {
    added.add(entryId);
    return CrdtMutation(doc: doc, delta: Uint8List.fromList([0xAD]));
  }

  @override
  CrdtMutation removeEntry(Uint8List doc, Uint8List entryId) {
    removed.add(entryId);
    return CrdtMutation(doc: doc, delta: Uint8List.fromList([0xDE]));
  }

  @override
  CrdtMutation setField(
    Uint8List doc,
    Uint8List entryId,
    int fieldId,
    Uint8List value,
    BigInt wallMs,
    int counter,
    Uint8List deviceId,
  ) {
    setFields.add((
      entryId: entryId,
      fieldId: fieldId,
      value: value,
      wallMs: wallMs,
      counter: counter,
    ));
    return CrdtMutation(doc: doc, delta: Uint8List.fromList([0x5E]));
  }

  @override
  HlcTick hlcTick(BigInt lastWallMs, int lastCounter, BigInt nowMs) =>
      nowMs > lastWallMs
      ? HlcTick(wallMs: nowMs, counter: 0)
      : HlcTick(wallMs: lastWallMs, counter: lastCounter + 1);

  @override
  Uint8List merge(Uint8List doc, Uint8List delta) {
    merged.add(delta);
    return doc; // merge identité : l'orchestration est ce qu'on teste.
  }

  @override
  HlcTick maxHlc(Uint8List doc) => maxHlcValue;

  // Non utilisés par les tests.
  @override
  Uint8List newEntryId() => throw UnimplementedError();
  @override
  Uint8List deviceIdFromKey(Uint8List publicKey) => throw UnimplementedError();
}

/// Reprojecteur qui enregistre ses appels (sans drift).
class FakeReprojector implements VaultReprojector {
  final List<Uint8List> reprojected = [];

  @override
  Future<void> reproject(Uint8List docBytes, Uint8List vaultKey) async {
    reprojected.add(docBytes);
  }
}

/// Store de doc en mémoire, pour tester le coordinateur sans drift.
class InMemoryVaultDocStore implements VaultDocStore {
  VaultDocState? state;
  int saves = 0;

  @override
  Future<VaultDocState?> load() async => state;

  @override
  Future<void> save(VaultDocState newState) async {
    state = newState;
    saves++;
  }
}

/// File de deltas en mémoire (FIFO), pour tester l'enfilement sans drift.
class InMemoryPendingDeltaStore implements PendingDeltaStore {
  final List<PendingDelta> deltas = [];
  int _nextId = 1;

  @override
  Future<void> enqueue(Uint8List payload) async {
    deltas.add(PendingDelta(id: _nextId++, payload: payload));
  }

  @override
  Future<List<PendingDelta>> peek(int limit) async =>
      deltas.take(limit).toList(growable: false);

  @override
  Future<void> ack(List<int> ids) async =>
      deltas.removeWhere((d) => ids.contains(d.id));

  @override
  Future<int> count() async => deltas.length;
}
