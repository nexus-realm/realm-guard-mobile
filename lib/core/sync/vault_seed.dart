import 'dart:typed_data';

import '../database/app_database.dart';
import 'vault_crdt.dart';
import 'vault_fields.dart';

/// Construit les entrées à semer depuis les lignes drift existantes (migration
/// v1 → doc CRDT). Fonction **pure** : les lignes sont fournies en mémoire.
///
/// La FK `profileId` (int local) est résolue vers le `syncId` (UUID) du profil
/// référencé, comme l'exige le format sur le fil. Une ligne sans `syncId` (cas
/// théorique post-migration) est ignorée ; un profil référencé mais absent
/// laisse la FK non émise (le champ profil est simplement omis).
List<SeedEntry> buildSeedEntries({
  required List<Profile> profiles,
  required List<Credential> credentials,
  required List<Totp> totps,
}) {
  final profileSyncId = <int, Uint8List>{
    for (final p in profiles)
      if (p.syncId != null) p.id: p.syncId!,
  };

  final entries = <SeedEntry>[];

  for (final profile in profiles) {
    final syncId = profile.syncId;
    if (syncId == null) continue;
    entries.add(
      SeedEntry(entryId: syncId, fields: VaultFieldMap.ofProfile(profile)),
    );
  }

  for (final credential in credentials) {
    final syncId = credential.syncId;
    if (syncId == null) continue;
    final profileId = credential.profileId;
    entries.add(
      SeedEntry(
        entryId: syncId,
        fields: VaultFieldMap.ofCredential(
          credential,
          profileSyncId: profileId == null ? null : profileSyncId[profileId],
        ),
      ),
    );
  }

  for (final totp in totps) {
    final syncId = totp.syncId;
    if (syncId == null) continue;
    final profileId = totp.profileId;
    entries.add(
      SeedEntry(
        entryId: syncId,
        fields: VaultFieldMap.ofTotp(
          totp,
          profileSyncId: profileId == null ? null : profileSyncId[profileId],
        ),
      ),
    );
  }

  return entries;
}
