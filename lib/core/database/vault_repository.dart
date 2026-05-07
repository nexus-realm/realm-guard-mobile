import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

class VaultRepository {
  final AppDatabase _db;

  VaultRepository(this._db);

  // Profiles
  Future<List<Profile>> getAllProfiles() => _db.profiles.select().get();

  Future<int> addProfile(String name, List<String> emails) =>
      _db.profiles.insertOne(
        ProfilesCompanion(name: Value(name), emails: Value(jsonEncode(emails))),
      );

  Future<bool> updateProfile(int id, String name, List<String> emails) =>
      _db.profiles.update().replace(
        ProfilesCompanion(
          id: Value(id),
          name: Value(name),
          emails: Value(jsonEncode(emails)),
        ),
      );

  Future<int> deleteProfile(int id) =>
      _db.profiles.deleteWhere((tbl) => tbl.id.equals(id));

  // Credentials
  Future<List<Credential>> getAllCredentials() =>
      _db.credentials.select().get();

  Future<List<Credential>> getCredentialsForProfile(int profileId) =>
      (_db.credentials.select()
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .get();

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

  Future<int> deleteCredential(int id) =>
      _db.credentials.deleteWhere((tbl) => tbl.id.equals(id));

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
}

class CredentialWithProfile {
  final Credential credential;
  final Profile? profile;

  CredentialWithProfile(this.credential, this.profile);
}
