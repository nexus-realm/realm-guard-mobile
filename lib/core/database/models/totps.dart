import 'package:drift/drift.dart';

import 'profiles.dart';
import 'sync_id.dart';

/// Secrets TOTP (RFC 6238). Le `secret` est stocké en Base32 (forme de
/// configuration standard) ; toute la base étant chiffrée par SQLCipher.
class Totps extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Clé stable de synchronisation (16 o) ⇔ `EntryId` du CRDT. Indexée unique
  /// (index créé en migration). `clientDefault` garantit un id sur toute
  /// insertion hors chemin CRDT.
  BlobColumn get syncId => blob().nullable().clientDefault(generateSyncId)();

  /// Libellé affiché (ex. « GitHub »).
  TextColumn get label => text()();

  /// Compte associé (ex. « me@example.com »).
  TextColumn get account => text().nullable()();

  /// Secret partagé, encodé en Base32.
  TextColumn get secret => text()();

  /// Paramètres TOTP (valeurs par défaut RFC 6238 / usage courant).
  IntColumn get digits => integer().withDefault(const Constant(6))();
  IntColumn get period => integer().withDefault(const Constant(30))();

  /// Algorithme HMAC : 'SHA1' (défaut), 'SHA256' ou 'SHA512'.
  TextColumn get algorithm => text().withDefault(const Constant('SHA1'))();

  IntColumn get profileId => integer().nullable().references(Profiles, #id)();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
