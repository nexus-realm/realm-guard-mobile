import 'package:drift/drift.dart';

/// File des deltas CRDT locaux **en attente de push** vers le serveur. L'`id`
/// auto-incrémenté donne l'ordre FIFO ; une ligne est supprimée une fois le
/// delta accepté par le serveur (`ack`). Chiffrée par SQLCipher comme le reste.
@DataClassName('PendingDeltaRow')
class PendingDeltas extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Delta encodé (opaque), tel que produit par le write-through.
  BlobColumn get payload => blob()();
}
