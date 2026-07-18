import 'package:drift/drift.dart';

/// Document CRDT du coffre (**source de vérité de la synchronisation**) et état
/// d'horloge HLC local, en **ligne unique** (`id` = 0). Stocké chiffré par
/// SQLCipher comme le reste de la base ; les valeurs de champ à l'intérieur du
/// doc sont en plus chiffrées par entrée (opaques au serveur).
class CrdtDocs extends Table {
  /// Toujours `0` : la table ne contient qu'une ligne.
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// `VaultDoc` encodé (postcard). Absent tant que le coffre CRDT n'est pas semé.
  BlobColumn get doc => blob()();

  /// Dernier HLC local émis — mur (ms epoch) + compteur — pour garantir la
  /// stricte monotonie des écritures à travers les redémarrages.
  IntColumn get hlcWall => integer().withDefault(const Constant(0))();
  IntColumn get hlcCounter => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
