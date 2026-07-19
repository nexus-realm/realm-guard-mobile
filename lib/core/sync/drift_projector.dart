import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'crdt_ffi.dart';
import 'vault_fields.dart';
import 'vault_projection.dart';
import 'vault_row_map.dart';

/// Bilan d'une reprojection : nombre d'entrées **réellement** changées (les
/// lignes identiques sont ignorées). Sert à signaler à l'utilisateur qu'un
/// tirage a modifié son coffre depuis un autre appareil.
class ReprojectionSummary {
  final int added;
  final int updated;
  final int removed;

  const ReprojectionSummary({
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
  });

  /// Total d'entrées ajoutées, modifiées ou supprimées.
  int get changed => added + updated + removed;
}

/// Issue d'un upsert d'entrée.
enum _Outcome { inserted, updated, unchanged }

/// Rend la base locale conforme au doc CRDT (abstrait pour tester l'orchestrateur
/// de synchro sans drift natif).
abstract interface class VaultReprojector {
  Future<ReprojectionSummary> reproject(Uint8List docBytes, Uint8List vaultKey);
}

/// Reprojection **doc CRDT → base drift** après un merge distant : la base locale
/// est rendue conforme au doc (source de vérité de la synchro). Upsert par
/// `syncId` (les lignes **inchangées ne sont pas réécrites**), résolution des FK
/// profil (UUID→int local), et **suppression** des lignes drift absentes du doc.
///
/// ⚠️ **Destructif** : supprime les lignes dont le `syncId` n'est plus dans le
/// doc. À n'appeler qu'après un merge/tirage réussi (doc autoritaire). Toute
/// l'opération est **transactionnelle**. Drift-couplé → couvert on-device.
class DriftProjector implements VaultReprojector {
  final AppDatabase _db;
  final CrdtFfi _ffi;

  DriftProjector(this._db, this._ffi);

  @override
  Future<ReprojectionSummary> reproject(
    Uint8List docBytes,
    Uint8List vaultKey,
  ) async {
    final entries = VaultProjection(_ffi).decode(docBytes, vaultKey);
    return _db.transaction(() async {
      var added = 0;
      var updated = 0;
      void tally(_Outcome outcome) {
        if (outcome == _Outcome.inserted) added++;
        if (outcome == _Outcome.updated) updated++;
      }

      // 1. Profils d'abord : leurs id locaux servent à résoudre les FK.
      for (final entry in entries) {
        if (entry.kind == VaultKind.profile) tally(await _upsertProfile(entry));
      }
      final profileIds = await _profileIdBySyncId();

      // 2. Credentials + TOTP, FK profil résolue en id local.
      for (final entry in entries) {
        switch (entry.kind) {
          case VaultKind.credential:
            tally(await _upsertCredential(entry, profileIds));
          case VaultKind.totp:
            tally(await _upsertTotp(entry, profileIds));
          case VaultKind.profile:
            break;
        }
      }

      // 3. Suppressions : lignes dont le syncId n'est plus dans le doc.
      final removed = await _deleteMissing(entries);

      return ReprojectionSummary(
        added: added,
        updated: updated,
        removed: removed,
      );
    });
  }

  int? _resolveProfile(DecodedEntry entry, Map<String, int> profileIds) {
    final ref = VaultRowMap.profileRef(entry);
    return ref == null ? null : profileIds[_hex(ref)];
  }

  Future<_Outcome> _upsertProfile(DecodedEntry entry) async {
    final companion = VaultRowMap.profile(entry);
    final existing = await (_db.select(
      _db.profiles,
    )..where((t) => t.syncId.equals(entry.syncId))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.profiles).insert(companion);
      return _Outcome.inserted;
    }
    if (_profileUnchanged(existing, companion)) return _Outcome.unchanged;
    await (_db.update(
      _db.profiles,
    )..where((t) => t.id.equals(existing.id))).write(companion);
    return _Outcome.updated;
  }

  Future<_Outcome> _upsertCredential(
    DecodedEntry entry,
    Map<String, int> profileIds,
  ) async {
    final companion = VaultRowMap.credential(
      entry,
      profileId: _resolveProfile(entry, profileIds),
    );
    final existing = await (_db.select(
      _db.credentials,
    )..where((t) => t.syncId.equals(entry.syncId))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.credentials).insert(companion);
      return _Outcome.inserted;
    }
    if (_credentialUnchanged(existing, companion)) return _Outcome.unchanged;
    await (_db.update(
      _db.credentials,
    )..where((t) => t.id.equals(existing.id))).write(companion);
    return _Outcome.updated;
  }

  Future<_Outcome> _upsertTotp(
    DecodedEntry entry,
    Map<String, int> profileIds,
  ) async {
    final companion = VaultRowMap.totp(
      entry,
      profileId: _resolveProfile(entry, profileIds),
    );
    final existing = await (_db.select(
      _db.totps,
    )..where((t) => t.syncId.equals(entry.syncId))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.totps).insert(companion);
      return _Outcome.inserted;
    }
    if (_totpUnchanged(existing, companion)) return _Outcome.unchanged;
    await (_db.update(
      _db.totps,
    )..where((t) => t.id.equals(existing.id))).write(companion);
    return _Outcome.updated;
  }

  // Comparaisons ligne existante ↔ companion projeté (champs synchronisés
  // seulement ; `id`/`updatedAt` sont locaux). `createdAt` absent = inchangé.
  bool _profileUnchanged(Profile row, ProfilesCompanion c) =>
      row.name == c.name.value &&
      row.emails == c.emails.value &&
      row.usernames == c.usernames.value &&
      row.phoneNumbers == c.phoneNumbers.value &&
      row.color == c.color.value &&
      row.note == c.note.value &&
      (!c.createdAt.present || row.createdAt == c.createdAt.value);

  bool _credentialUnchanged(Credential row, CredentialsCompanion c) =>
      row.title == c.title.value &&
      row.username == c.username.value &&
      row.password == c.password.value &&
      row.uri == c.uri.value &&
      row.notes == c.notes.value &&
      row.customFields == c.customFields.value &&
      row.favorite == c.favorite.value &&
      row.profileId == c.profileId.value &&
      (!c.createdAt.present || row.createdAt == c.createdAt.value);

  bool _totpUnchanged(Totp row, TotpsCompanion c) =>
      row.label == c.label.value &&
      row.account == c.account.value &&
      row.secret == c.secret.value &&
      row.digits == c.digits.value &&
      row.period == c.period.value &&
      row.algorithm == c.algorithm.value &&
      row.favorite == c.favorite.value &&
      row.profileId == c.profileId.value &&
      (!c.createdAt.present || row.createdAt == c.createdAt.value);

  Future<Map<String, int>> _profileIdBySyncId() async {
    final rows = await _db.select(_db.profiles).get();
    return {
      for (final row in rows)
        if (row.syncId != null) _hex(row.syncId!): row.id,
    };
  }

  Future<int> _deleteMissing(List<DecodedEntry> entries) async {
    Set<String> keep(VaultKind kind) => {
      for (final entry in entries)
        if (entry.kind == kind) _hex(entry.syncId),
    };

    return await _deleteProfilesExcept(keep(VaultKind.profile)) +
        await _deleteCredentialsExcept(keep(VaultKind.credential)) +
        await _deleteTotpsExcept(keep(VaultKind.totp));
  }

  Future<int> _deleteProfilesExcept(Set<String> keep) async {
    final rows = await _db.select(_db.profiles).get();
    final ids = _idsToDelete(rows.map((r) => (r.id, r.syncId)), keep);
    if (ids.isEmpty) return 0;
    return (_db.delete(_db.profiles)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> _deleteCredentialsExcept(Set<String> keep) async {
    final rows = await _db.select(_db.credentials).get();
    final ids = _idsToDelete(rows.map((r) => (r.id, r.syncId)), keep);
    if (ids.isEmpty) return 0;
    return (_db.delete(_db.credentials)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> _deleteTotpsExcept(Set<String> keep) async {
    final rows = await _db.select(_db.totps).get();
    final ids = _idsToDelete(rows.map((r) => (r.id, r.syncId)), keep);
    if (ids.isEmpty) return 0;
    return (_db.delete(_db.totps)..where((t) => t.id.isIn(ids))).go();
  }

  /// Ids des lignes à supprimer : celles dont le `syncId` n'est pas dans [keep]
  /// (y compris un `syncId` nul — cas théorique post-migration).
  List<int> _idsToDelete(Iterable<(int, Uint8List?)> rows, Set<String> keep) =>
      [
        for (final (id, syncId) in rows)
          if (syncId == null || !keep.contains(_hex(syncId))) id,
      ];

  String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
