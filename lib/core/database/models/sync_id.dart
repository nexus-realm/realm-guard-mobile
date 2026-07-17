import 'dart:math';
import 'dart:typed_data';

/// Génère un identifiant de synchronisation (16 octets aléatoires) — la clé
/// stable d'une ligne dans le CRDT (`EntryId`), indépendante de la PK locale
/// auto-incrémentée. Sert de `clientDefault` : toute ligne créée hors du chemin
/// CRDT reçoit malgré tout un `syncId`. Le chemin CRDT (P3.3c) fournira à la
/// place l'`EntryId` de l'entrée.
Uint8List generateSyncId() {
  final rng = Random.secure();
  return Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
}
