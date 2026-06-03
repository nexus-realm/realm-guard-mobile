import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/home/data/profile_deletion_strategy.dart';
import 'app_database.dart';

/// Lecture réactive dont la vue Home a besoin. Permet d'injecter un faux
/// dépôt en test sans dépendre de sqlite3 natif.
abstract interface class HomeRepository {
  Stream<List<Profile>> watchAllProfiles();
  Stream<List<CredentialWithProfile>> watchCredentialsWithProfiles();
}

/// Opérations d'écriture/lecture nécessaires aux pages d'ajout. Permet
/// d'injecter un faux dépôt en test sans dépendre de sqlite3 natif.
abstract interface class VaultEditor {
  Future<List<Profile>> getAllProfiles();
  Future<int> addProfile(String name, List<String> emails);
  Future<int> addCredential(String title, String encryptedData, int? profileId);
}

/// Consultation / modification / suppression d'un profil existant.
abstract interface class ProfileEditor {
  Stream<Profile?> watchProfile(int id);
  Future<bool> updateProfile(int id, String name, List<String> emails);
  Future<int> countCredentialsForProfile(int profileId);
  Future<void> deleteProfile(int id, ProfileDeletionStrategy strategy);
}

/// Consultation / modification / suppression d'un identifiant existant, avec
/// la liste des profils disponibles pour la (ré)association.
abstract interface class CredentialEditor {
  Stream<CredentialWithProfile?> watchCredential(int id);
  Future<List<Profile>> getAllProfiles();
  Future<bool> updateCredential(
    int id,
    String title,
    String encryptedData,
    int? profileId,
  );
  Future<int> deleteCredential(int id);
}

class VaultRepository
    implements HomeRepository, VaultEditor, ProfileEditor, CredentialEditor {
  final AppDatabase _db;

  VaultRepository(this._db);

  // Profiles
  @override
  Future<List<Profile>> getAllProfiles() => _db.profiles.select().get();

  @override
  Stream<List<Profile>> watchAllProfiles() => _db.profiles.select().watch();

  @override
  Stream<Profile?> watchProfile(int id) =>
      (_db.profiles.select()..where((tbl) => tbl.id.equals(id)))
          .watchSingleOrNull();

  @override
  Future<int> addProfile(String name, List<String> emails) =>
      _db.profiles.insertOne(
        ProfilesCompanion(name: Value(name), emails: Value(jsonEncode(emails))),
      );

  @override
  Future<bool> updateProfile(int id, String name, List<String> emails) =>
      _db.profiles.update().replace(
        ProfilesCompanion(
          id: Value(id),
          name: Value(name),
          emails: Value(jsonEncode(emails)),
        ),
      );

  @override
  Future<int> countCredentialsForProfile(int profileId) async {
    final countExp = _db.credentials.id.count();
    final query = _db.credentials.selectOnly()
      ..addColumns([countExp])
      ..where(_db.credentials.profileId.equals(profileId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Supprime un profil. Selon [strategy], les identifiants liés sont soit
  /// dissociés (profileId → null), soit supprimés. Opération atomique.
  @override
  Future<void> deleteProfile(int id, ProfileDeletionStrategy strategy) {
    return _db.transaction(() async {
      switch (strategy) {
        case ProfileDeletionStrategy.dissociate:
          await (_db.credentials.update()
                ..where((tbl) => tbl.profileId.equals(id)))
              .write(const CredentialsCompanion(profileId: Value(null)));
        case ProfileDeletionStrategy.cascade:
          await (_db.credentials.delete()
                ..where((tbl) => tbl.profileId.equals(id)))
              .go();
      }
      await (_db.profiles.delete()..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  // Credentials
  Future<List<Credential>> getAllCredentials() =>
      _db.credentials.select().get();

  Future<List<Credential>> getCredentialsForProfile(int profileId) =>
      (_db.credentials.select()
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .get();

  @override
  Future<int> addCredential(
    String title,
    String encryptedData,
    int? profileId,
  ) => _db.credentials.insertOne(
    CredentialsCompanion(
      title: Value(title),
      encryptedData: Value(encryptedData),
      profileId: Value(profileId),
    ),
  );

  @override
  Future<bool> updateCredential(
    int id,
    String title,
    String encryptedData,
    int? profileId,
  ) => _db.credentials.update().replace(
    CredentialsCompanion(
      id: Value(id),
      title: Value(title),
      encryptedData: Value(encryptedData),
      profileId: Value(profileId),
    ),
  );

  @override
  Future<int> deleteCredential(int id) =>
      _db.credentials.deleteWhere((tbl) => tbl.id.equals(id));

  @override
  Stream<CredentialWithProfile?> watchCredential(int id) {
    final query = _db.credentials.select().join([
      leftOuterJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.credentials.profileId),
      ),
    ])..where(_db.credentials.id.equals(id));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final credential = row.readTable(_db.credentials);
      final profile = row.readTableOrNull(_db.profiles);
      return CredentialWithProfile(credential, profile);
    });
  }

  // Combined
  Future<List<CredentialWithProfile>> getCredentialsWithProfiles() async {
    final query = _db.credentials.select().join([
      leftOuterJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.credentials.profileId),
      ),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final credential = row.readTable(_db.credentials);
      final profile = row.readTableOrNull(_db.profiles);
      return CredentialWithProfile(credential, profile);
    }).toList();
  }

  @override
  Stream<List<CredentialWithProfile>> watchCredentialsWithProfiles() {
    final query = _db.credentials.select().join([
      leftOuterJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.credentials.profileId),
      ),
    ]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final credential = row.readTable(_db.credentials);
        final profile = row.readTableOrNull(_db.profiles);
        return CredentialWithProfile(credential, profile);
      }).toList(),
    );
  }
}

class CredentialWithProfile {
  final Credential credential;
  final Profile? profile;

  CredentialWithProfile(this.credential, this.profile);
}
