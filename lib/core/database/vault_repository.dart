import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/home/data/credential_draft.dart';
import '../../features/home/data/custom_field.dart';
import '../../features/home/data/profile_deletion_strategy.dart';
import '../../features/home/data/profile_draft.dart';
import '../../features/home/data/totp_draft.dart';
import '../sync/vault_crdt.dart';
import '../sync/vault_fields.dart';
import 'app_database.dart';

/// Lecture réactive dont la vue Home a besoin. Permet d'injecter un faux
/// dépôt en test sans dépendre de sqlite3 natif.
abstract interface class HomeRepository {
  Stream<List<Profile>> watchAllProfiles();
  Stream<List<CredentialWithProfile>> watchCredentialsWithProfiles();
  Stream<List<TotpWithProfile>> watchTotpsWithProfiles();
}

/// Opérations d'écriture/lecture nécessaires aux pages d'ajout. Permet
/// d'injecter un faux dépôt en test sans dépendre de sqlite3 natif.
abstract interface class VaultEditor {
  Future<List<Profile>> getAllProfiles();
  Future<int> addProfile(ProfileDraft draft);
  Future<int> addCredential(CredentialDraft draft);
}

/// Consultation / modification / suppression d'un profil existant.
abstract interface class ProfileEditor {
  Stream<Profile?> watchProfile(int id);
  Future<bool> updateProfile(int id, ProfileDraft draft);
  Future<int> countCredentialsForProfile(int profileId);
  Future<void> deleteProfile(int id, ProfileDeletionStrategy strategy);

  /// Éléments rattachés au profil (consultation réactive depuis sa fiche).
  Stream<List<Credential>> watchCredentialsForProfile(int profileId);
  Stream<List<Totp>> watchTotpsForProfile(int profileId);
}

/// Consultation / modification / suppression d'un identifiant existant, avec
/// la liste des profils disponibles pour la (ré)association.
abstract interface class CredentialEditor {
  Stream<CredentialWithProfile?> watchCredential(int id);
  Future<List<Profile>> getAllProfiles();
  Future<bool> updateCredential(int id, CredentialDraft draft);
  Future<int> deleteCredential(int id);
}

/// Lecture réactive des TOTP (liste pour l'onglet Vault).
abstract interface class TotpReader {
  Stream<List<TotpWithProfile>> watchTotpsWithProfiles();
}

/// Création / consultation / modification / suppression d'un TOTP, avec la
/// liste des profils pour l'association.
abstract interface class TotpEditor {
  Future<List<Profile>> getAllProfiles();
  Future<int> addTotp(TotpDraft draft);
  Stream<TotpWithProfile?> watchTotp(int id);
  Future<bool> updateTotp(int id, TotpDraft draft);
  Future<int> deleteTotp(int id);
}

class VaultRepository
    implements
        HomeRepository,
        VaultEditor,
        ProfileEditor,
        CredentialEditor,
        TotpReader,
        TotpEditor {
  final AppDatabase _db;

  /// Ouvre la session CRDT (write-through de la synchro), ou `null` si la synchro
  /// n'est pas câblée (tests) / coffre verrouillé. Résolue paresseusement.
  final Future<VaultCrdt?> Function()? _crdtSession;

  VaultRepository(this._db, {Future<VaultCrdt?> Function()? crdtSession})
    : _crdtSession = crdtSession;

  Future<VaultCrdt?> _crdt() async =>
      _crdtSession == null ? null : await _crdtSession();

  /// Exécute une écriture **de synchro** best-effort : le doc CRDT est un artefact
  /// *fantôme* (les lectures restent servies par drift), donc tout échec est
  /// avalé — il ne doit jamais casser l'opération drift déjà réussie.
  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Non fatal : la synchro rattrapera (reprojection / reseed) ultérieurement.
    }
  }

  Future<Uint8List?> _profileSyncId(int? profileId) async {
    if (profileId == null) return null;
    final row =
        await (_db.profiles.select()..where((t) => t.id.equals(profileId)))
            .getSingleOrNull();
    return row?.syncId;
  }

  Future<void> _syncProfile(int id, {required bool isNew}) =>
      _bestEffort(() async {
        final crdt = await _crdt();
        if (crdt == null) return;
        final row = await (_db.profiles.select()..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        final syncId = row?.syncId;
        if (row == null || syncId == null) return;
        await crdt.putEntry(
          entryId: syncId,
          fields: VaultFieldMap.ofProfile(row, clearNulls: !isNew),
          isNew: isNew,
        );
      });

  Future<void> _syncCredential(int id, {required bool isNew}) =>
      _bestEffort(() async {
        final crdt = await _crdt();
        if (crdt == null) return;
        final row =
            await (_db.credentials.select()..where((t) => t.id.equals(id)))
                .getSingleOrNull();
        final syncId = row?.syncId;
        if (row == null || syncId == null) return;
        await crdt.putEntry(
          entryId: syncId,
          fields: VaultFieldMap.ofCredential(
            row,
            profileSyncId: await _profileSyncId(row.profileId),
            clearNulls: !isNew,
          ),
          isNew: isNew,
        );
      });

  Future<void> _syncTotp(int id, {required bool isNew}) =>
      _bestEffort(() async {
        final crdt = await _crdt();
        if (crdt == null) return;
        final row = await (_db.totps.select()..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        final syncId = row?.syncId;
        if (row == null || syncId == null) return;
        await crdt.putEntry(
          entryId: syncId,
          fields: VaultFieldMap.ofTotp(
            row,
            profileSyncId: await _profileSyncId(row.profileId),
            clearNulls: !isNew,
          ),
          isNew: isNew,
        );
      });

  Future<void> _removeEntry(Uint8List? syncId) => _bestEffort(() async {
    if (syncId == null) return;
    final crdt = await _crdt();
    if (crdt == null) return;
    await crdt.removeEntry(syncId);
  });

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
  Future<int> addProfile(ProfileDraft draft) async {
    final id = await _db.profiles.insertOne(_profileCompanion(draft));
    await _syncProfile(id, isNew: true);
    return id;
  }

  @override
  Future<bool> updateProfile(int id, ProfileDraft draft) async {
    final rows =
        await (_db.profiles.update()..where((tbl) => tbl.id.equals(id))).write(
          _profileCompanion(draft, updatedAt: DateTime.now()),
        );
    if (rows > 0) await _syncProfile(id, isNew: false);
    return rows > 0;
  }

  ProfilesCompanion _profileCompanion(
    ProfileDraft draft, {
    DateTime? updatedAt,
  }) {
    return ProfilesCompanion(
      name: Value(draft.name),
      emails: Value(jsonEncode(draft.emails)),
      usernames: Value(jsonEncode(draft.usernames)),
      phoneNumbers: Value(jsonEncode(draft.phoneNumbers)),
      color: Value(draft.color),
      note: Value(draft.note),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
    );
  }

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
  Future<void> deleteProfile(int id, ProfileDeletionStrategy strategy) async {
    // Capturés avant la transaction : les lignes disparaissent ensuite.
    final profile =
        await (_db.profiles.select()..where((tbl) => tbl.id.equals(id)))
            .getSingleOrNull();
    final affected =
        await (_db.credentials.select()
              ..where((tbl) => tbl.profileId.equals(id)))
            .get();

    await _db.transaction(() async {
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

    // Répercussion sur le doc CRDT (chaque appel est déjà best-effort).
    switch (strategy) {
      case ProfileDeletionStrategy.dissociate:
        // profileId désormais null en base ⇒ effacement de la FK dans le doc.
        for (final credential in affected) {
          await _syncCredential(credential.id, isNew: false);
        }
      case ProfileDeletionStrategy.cascade:
        for (final credential in affected) {
          await _removeEntry(credential.syncId);
        }
    }
    await _removeEntry(profile?.syncId);
  }

  @override
  Stream<List<Credential>> watchCredentialsForProfile(int profileId) =>
      (_db.credentials.select()
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .watch();

  @override
  Stream<List<Totp>> watchTotpsForProfile(int profileId) =>
      (_db.totps.select()..where((tbl) => tbl.profileId.equals(profileId)))
          .watch();

  // Credentials
  Future<List<Credential>> getAllCredentials() =>
      _db.credentials.select().get();

  Future<List<Credential>> getCredentialsForProfile(int profileId) =>
      (_db.credentials.select()
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .get();

  @override
  Future<int> addCredential(CredentialDraft draft) async {
    final id = await _db.credentials.insertOne(_credentialCompanion(draft));
    await _syncCredential(id, isNew: true);
    return id;
  }

  @override
  Future<bool> updateCredential(int id, CredentialDraft draft) async {
    final rows =
        await (_db.credentials.update()..where((tbl) => tbl.id.equals(id)))
            .write(_credentialCompanion(draft, updatedAt: DateTime.now()));
    if (rows > 0) await _syncCredential(id, isNew: false);
    return rows > 0;
  }

  CredentialsCompanion _credentialCompanion(
    CredentialDraft draft, {
    DateTime? updatedAt,
  }) {
    return CredentialsCompanion(
      title: Value(draft.title),
      username: Value(draft.username),
      password: Value(draft.password),
      uri: Value(draft.uri),
      notes: Value(draft.notes),
      customFields: Value(CustomField.encode(draft.customFields)),
      favorite: Value(draft.favorite),
      profileId: Value(draft.profileId),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
    );
  }

  @override
  Future<int> deleteCredential(int id) async {
    final row =
        await (_db.credentials.select()..where((tbl) => tbl.id.equals(id)))
            .getSingleOrNull();
    final count = await _db.credentials.deleteWhere((tbl) => tbl.id.equals(id));
    await _removeEntry(row?.syncId);
    return count;
  }

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

  // TOTP
  TotpsCompanion _totpCompanion(TotpDraft draft, {DateTime? updatedAt}) {
    return TotpsCompanion(
      label: Value(draft.label),
      account: Value(draft.account),
      secret: Value(draft.secret),
      digits: Value(draft.digits),
      period: Value(draft.period),
      algorithm: Value(draft.algorithm),
      profileId: Value(draft.profileId),
      favorite: Value(draft.favorite),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
    );
  }

  @override
  Future<int> addTotp(TotpDraft draft) async {
    final id = await _db.totps.insertOne(_totpCompanion(draft));
    await _syncTotp(id, isNew: true);
    return id;
  }

  @override
  Future<bool> updateTotp(int id, TotpDraft draft) async {
    final rows = await (_db.totps.update()..where((tbl) => tbl.id.equals(id)))
        .write(_totpCompanion(draft, updatedAt: DateTime.now()));
    if (rows > 0) await _syncTotp(id, isNew: false);
    return rows > 0;
  }

  @override
  Future<int> deleteTotp(int id) async {
    final row = await (_db.totps.select()..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    final count = await _db.totps.deleteWhere((tbl) => tbl.id.equals(id));
    await _removeEntry(row?.syncId);
    return count;
  }

  @override
  Stream<TotpWithProfile?> watchTotp(int id) {
    final query = _db.totps.select().join([
      leftOuterJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.totps.profileId),
      ),
    ])..where(_db.totps.id.equals(id));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return TotpWithProfile(
        row.readTable(_db.totps),
        row.readTableOrNull(_db.profiles),
      );
    });
  }

  @override
  Stream<List<TotpWithProfile>> watchTotpsWithProfiles() {
    final query = _db.totps.select().join([
      leftOuterJoin(
        _db.profiles,
        _db.profiles.id.equalsExp(_db.totps.profileId),
      ),
    ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => TotpWithProfile(
              row.readTable(_db.totps),
              row.readTableOrNull(_db.profiles),
            ),
          )
          .toList(),
    );
  }
}

class CredentialWithProfile {
  final Credential credential;
  final Profile? profile;

  CredentialWithProfile(this.credential, this.profile);
}

class TotpWithProfile {
  final Totp totp;
  final Profile? profile;

  TotpWithProfile(this.totp, this.profile);
}
