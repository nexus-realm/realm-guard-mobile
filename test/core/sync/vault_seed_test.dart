import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';
import 'package:realmguard/core/sync/vault_seed.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000);
Uint8List _sync(int fill) => Uint8List.fromList(List.filled(16, fill));

Profile _profile(int id, Uint8List syncId) => Profile(
  id: id,
  syncId: syncId,
  name: 'Perso',
  emails: '[]',
  usernames: '[]',
  phoneNumbers: '[]',
  createdAt: _epoch,
  updatedAt: _epoch,
);

Credential _credential(int id, Uint8List syncId, {int? profileId}) => Credential(
  id: id,
  syncId: syncId,
  title: 'GitHub',
  customFields: '[]',
  favorite: false,
  profileId: profileId,
  createdAt: _epoch,
  updatedAt: _epoch,
);

Totp _totp(int id, Uint8List syncId, {int? profileId}) => Totp(
  id: id,
  syncId: syncId,
  label: 'GitHub',
  secret: 'JBSWY3DPEHPK3PXP',
  digits: 6,
  period: 30,
  algorithm: 'SHA1',
  favorite: false,
  profileId: profileId,
  createdAt: _epoch,
  updatedAt: _epoch,
);

void main() {
  group('buildSeedEntries', () {
    test('une entrée par ligne, identifiée par son syncId', () {
      final entries = buildSeedEntries(
        profiles: [_profile(1, _sync(1))],
        credentials: [_credential(2, _sync(2))],
        totps: [_totp(3, _sync(3))],
      );
      expect(entries.length, 3);
      expect(entries.map((e) => e.entryId), [_sync(1), _sync(2), _sync(3)]);
      expect(entries[0].fields[VaultFields.kind], const IntValue(0));
      expect(entries[1].fields[VaultFields.kind], const IntValue(1));
      expect(entries[2].fields[VaultFields.kind], const IntValue(2));
    });

    test('FK profileId résolue vers le syncId (UUID) du profil', () {
      final profileSync = _sync(9);
      final entries = buildSeedEntries(
        profiles: [_profile(1, profileSync)],
        credentials: [_credential(2, _sync(2), profileId: 1)],
        totps: [_totp(3, _sync(3), profileId: 1)],
      );
      // Ordre garanti : profils, puis credentials, puis totps.
      final cred = entries[1];
      final totp = entries[2];
      expect(cred.fields[VaultFields.credentialProfileId], UuidValue(profileSync));
      expect(totp.fields[VaultFields.totpProfileId], UuidValue(profileSync));
    });

    test('profil référencé absent ⇒ FK omise', () {
      final entries = buildSeedEntries(
        profiles: const [],
        credentials: [_credential(2, _sync(2), profileId: 99)],
        totps: const [],
      );
      final cred = entries.single;
      expect(cred.fields.containsKey(VaultFields.credentialProfileId), isFalse);
    });

    test('sans profileId ⇒ FK omise', () {
      final entries = buildSeedEntries(
        profiles: const [],
        credentials: [_credential(2, _sync(2))],
        totps: const [],
      );
      expect(
        entries.single.fields.containsKey(VaultFields.credentialProfileId),
        isFalse,
      );
    });
  });
}
