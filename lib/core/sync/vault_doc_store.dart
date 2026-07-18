import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'crdt_ffi.dart' show HlcTick;

/// État CRDT persisté : le `VaultDoc` encodé + le dernier HLC local émis.
class VaultDocState {
  /// `VaultDoc` encodé (source de vérité locale de la synchro).
  final Uint8List doc;

  /// Dernière horloge HLC locale, pour la stricte monotonie des écritures.
  final HlcTick clock;

  const VaultDocState({required this.doc, required this.clock});
}

/// Persistance du [VaultDocState] (abstrait pour la testabilité).
abstract interface class VaultDocStore {
  /// État persisté, ou `null` si le coffre CRDT n'a pas encore été semé.
  Future<VaultDocState?> load();

  /// Persiste le doc + l'horloge (ligne unique, écrasement).
  Future<void> save(VaultDocState state);
}

/// Implémentation drift : ligne unique de la table `crdt_docs`, dans la base
/// SQLCipher du coffre.
class DriftVaultDocStore implements VaultDocStore {
  final AppDatabase _db;

  const DriftVaultDocStore(this._db);

  @override
  Future<VaultDocState?> load() async {
    final row = await (_db.select(
      _db.crdtDocs,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return null;
    return VaultDocState(
      doc: row.doc,
      clock: HlcTick(wallMs: BigInt.from(row.hlcWall), counter: row.hlcCounter),
    );
  }

  @override
  Future<void> save(VaultDocState state) async {
    await _db
        .into(_db.crdtDocs)
        .insertOnConflictUpdate(
          CrdtDocsCompanion(
            id: const Value(0),
            doc: Value(state.doc),
            hlcWall: Value(state.clock.wallMs.toInt()),
            hlcCounter: Value(state.clock.counter),
          ),
        );
  }
}
