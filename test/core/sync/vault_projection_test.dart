import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';
import 'package:realmguard/core/sync/vault_projection.dart';

import '../../support/sync_test_doubles.dart';

Uint8List _id(int fill) => Uint8List.fromList(List.filled(16, fill));
CrdtField _cf(int fieldId, FieldValue value) =>
    CrdtField(fieldId: fieldId, value: value.encode());

void main() {
  final vaultKey = Uint8List.fromList([1, 2, 3]);

  group('VaultProjection.decode', () {
    test('projette profil + credential, exclut le champ kind', () {
      final profileId = _id(1);
      final credId = _id(2);
      final refProfile = _id(9);

      final ffi = FakeCrdtFfi(
        ids: [profileId, credId],
        fieldsById: {
          FakeCrdtFfi.hex(profileId): [
            _cf(VaultFields.kind, const IntValue(0)),
            _cf(VaultFields.profileName, const TextValue('Perso')),
            _cf(VaultFields.profileEmails, const TextValue('["a@b.c"]')),
          ],
          FakeCrdtFfi.hex(credId): [
            _cf(VaultFields.kind, const IntValue(1)),
            _cf(VaultFields.credentialTitle, const TextValue('GitHub')),
            _cf(VaultFields.credentialFavorite, const BoolValue(true)),
            _cf(VaultFields.credentialProfileId, UuidValue(refProfile)),
            _cf(VaultFields.credentialCreatedAt, const IntValue(1700000000000)),
          ],
        },
      );

      final decoded = VaultProjection(ffi).decode(Uint8List(0), vaultKey);
      expect(decoded.length, 2);

      final profile = decoded.firstWhere((e) => e.kind == VaultKind.profile);
      expect(profile.syncId, profileId);
      expect(profile.fields[VaultFields.profileName], const TextValue('Perso'));
      expect(profile.fields.containsKey(VaultFields.kind), isFalse);

      final cred = decoded.firstWhere((e) => e.kind == VaultKind.credential);
      expect(cred.fields[VaultFields.credentialFavorite], const BoolValue(true));
      expect(cred.fields[VaultFields.credentialProfileId], UuidValue(refProfile));
      expect(
        (cred.fields[VaultFields.credentialCreatedAt] as IntValue).value,
        1700000000000,
      );
    });

    test('ignore une entrée sans kind ou de kind inconnu', () {
      final noKind = _id(3);
      final unknown = _id(4);
      final ffi = FakeCrdtFfi(
        ids: [noKind, unknown],
        fieldsById: {
          FakeCrdtFfi.hex(noKind): [
            _cf(VaultFields.profileName, const TextValue('orphelin')),
          ],
          FakeCrdtFfi.hex(unknown): [_cf(VaultFields.kind, const IntValue(99))],
        },
      );
      expect(VaultProjection(ffi).decode(Uint8List(0), vaultKey), isEmpty);
    });
  });

  group('VaultDocWriter.putFields', () {
    test('chiffre chaque champ, HLC strictement croissant, création marquée', () {
      final ffi = FakeCrdtFfi();
      final entryId = _id(7);
      final deviceId = _id(8);

      final result = VaultDocWriter(ffi).putFields(
        doc: Uint8List(0),
        entryId: entryId,
        deviceId: deviceId,
        vaultKey: vaultKey,
        fields: {
          VaultFields.kind: const IntValue(1),
          VaultFields.credentialTitle: const TextValue('GH'),
        },
        clock: HlcTick(wallMs: BigInt.from(100), counter: 0),
        nowMs: BigInt.from(100), // now == wall ⇒ le compteur s'incrémente
        markPresent: true,
      );

      // Présence marquée puis un set_field par champ (ordre d'insertion).
      expect(ffi.added, [entryId]);
      expect(ffi.setFields.length, 2);
      expect(ffi.setFields[0].fieldId, VaultFields.kind);
      expect(ffi.setFields[1].fieldId, VaultFields.credentialTitle);

      // HLC : (100,1) puis (100,2) — strictement croissant.
      expect(ffi.setFields[0].wallMs, BigInt.from(100));
      expect(ffi.setFields[0].counter, 1);
      expect(ffi.setFields[1].counter, 2);
      expect(result.clock.counter, 2);

      // Les valeurs chiffrées (identité) redonnent les FieldValue d'origine.
      expect(FieldValue.decode(ffi.setFields[1].value), const TextValue('GH'));

      // add_entry + 2 set_field ⇒ 3 deltas.
      expect(result.deltas.length, 3);
    });

    test('sans markPresent : pas d\'add_entry', () {
      final ffi = FakeCrdtFfi();
      VaultDocWriter(ffi).putFields(
        doc: Uint8List(0),
        entryId: _id(7),
        deviceId: _id(8),
        vaultKey: vaultKey,
        fields: {VaultFields.credentialPassword: const TextValue('s3cret')},
        clock: HlcTick(wallMs: BigInt.zero, counter: 0),
        nowMs: BigInt.from(1700000000000),
      );
      expect(ffi.added, isEmpty);
      expect(ffi.setFields.single.fieldId, VaultFields.credentialPassword);
      // now > wall ⇒ nouvelle ms, compteur 0.
      expect(ffi.setFields.single.wallMs, BigInt.from(1700000000000));
      expect(ffi.setFields.single.counter, 0);
    });
  });
}
