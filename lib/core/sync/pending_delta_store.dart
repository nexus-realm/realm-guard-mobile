import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Un delta local en attente de push : son `id` FIFO + sa charge utile opaque.
class PendingDelta {
  final int id;
  final Uint8List payload;

  const PendingDelta({required this.id, required this.payload});
}

/// File des deltas locaux en attente de push (abstrait pour la testabilité).
abstract interface class PendingDeltaStore {
  /// Ajoute un delta en fin de file.
  Future<void> enqueue(Uint8List payload);

  /// Les [limit] plus anciens deltas (FIFO), sans les retirer.
  Future<List<PendingDelta>> peek(int limit);

  /// Retire les deltas [ids] (acceptés par le serveur).
  Future<void> ack(List<int> ids);

  /// Nombre de deltas en attente.
  Future<int> count();
}

/// Implémentation drift : table `pending_deltas`, ordre FIFO par `id`.
class DriftPendingDeltaStore implements PendingDeltaStore {
  final AppDatabase _db;

  const DriftPendingDeltaStore(this._db);

  @override
  Future<void> enqueue(Uint8List payload) async {
    await _db
        .into(_db.pendingDeltas)
        .insert(PendingDeltasCompanion(payload: Value(payload)));
  }

  @override
  Future<List<PendingDelta>> peek(int limit) async {
    final rows =
        await (_db.select(_db.pendingDeltas)
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(limit))
            .get();
    return rows
        .map((row) => PendingDelta(id: row.id, payload: row.payload))
        .toList(growable: false);
  }

  @override
  Future<void> ack(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.pendingDeltas)..where((t) => t.id.isIn(ids))).go();
  }

  @override
  Future<int> count() async {
    final countExp = _db.pendingDeltas.id.count();
    final query = _db.selectOnly(_db.pendingDeltas)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }
}
