import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';
import 'package:realmguard/core/sync/vault_projection.dart';

typedef _SetFieldCall = ({
  Uint8List entryId,
  int fieldId,
  Uint8List value,
  BigInt wallMs,
  int counter,
});

/// Faux FFI CRDT : le chiffrement est l'**identité** (le « Ciphertext » est le
/// clair encodé), l'HLC suit la règle du cœur (`next_local`), et les mutations
/// enregistrent leurs appels. Aucune lib native.
class _FakeCrdtFfi implements CrdtFfi {
  final List<Uint8List> ids;
  final Map<String, List<CrdtField>> fieldsById;

  final List<_SetFieldCall> setFields = [];
  final List<Uint8List> added = [];

  _FakeCrdtFfi({this.ids = const [], this.fieldsById = const {}});

  static String hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  List<Uint8List> entryIds(Uint8List doc) => ids;

  @override
  List<CrdtField> entryFields(Uint8List doc, Uint8List entryId) =>
      fieldsById[hex(entryId)] ?? const [];

  @override
  Uint8List decryptField(Uint8List vaultKey, Uint8List entryId, Uint8List value) =>
      value;

  @override
  Uint8List encryptField(
    Uint8List vaultKey,
    Uint8List entryId,
    Uint8List plaintext,
  ) => plaintext;

  @override
  CrdtMutation addEntry(Uint8List doc, Uint8List entryId, Uint8List deviceId) {
    added.add(entryId);
    return CrdtMutation(doc: doc, delta: Uint8List.fromList([0xAD]));
  }

  @override
  CrdtMutation setField(
    Uint8List doc,
    Uint8List entryId,
    int fieldId,
    Uint8List value,
    BigInt wallMs,
    int counter,
    Uint8List deviceId,
  ) {
    setFields.add((
      entryId: entryId,
      fieldId: fieldId,
      value: value,
      wallMs: wallMs,
      counter: counter,
    ));
    return CrdtMutation(doc: doc, delta: Uint8List.fromList([0x5E]));
  }

  @override
  HlcTick hlcTick(BigInt lastWallMs, int lastCounter, BigInt nowMs) =>
      nowMs > lastWallMs
      ? HlcTick(wallMs: nowMs, counter: 0)
      : HlcTick(wallMs: lastWallMs, counter: lastCounter + 1);

  // Non utilisés par ces tests.
  @override
  Uint8List newDoc() => throw UnimplementedError();
  @override
  Uint8List newEntryId() => throw UnimplementedError();
  @override
  Uint8List deviceIdFromKey(Uint8List publicKey) => throw UnimplementedError();
  @override
  CrdtMutation removeEntry(Uint8List doc, Uint8List entryId) =>
      throw UnimplementedError();
  @override
  Uint8List merge(Uint8List doc, Uint8List delta) => throw UnimplementedError();
}

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

      final ffi = _FakeCrdtFfi(
        ids: [profileId, credId],
        fieldsById: {
          _FakeCrdtFfi.hex(profileId): [
            _cf(VaultFields.kind, const IntValue(0)),
            _cf(VaultFields.profileName, const TextValue('Perso')),
            _cf(VaultFields.profileEmails, const TextValue('["a@b.c"]')),
          ],
          _FakeCrdtFfi.hex(credId): [
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
      final ffi = _FakeCrdtFfi(
        ids: [noKind, unknown],
        fieldsById: {
          _FakeCrdtFfi.hex(noKind): [
            _cf(VaultFields.profileName, const TextValue('orphelin')),
          ],
          _FakeCrdtFfi.hex(unknown): [_cf(VaultFields.kind, const IntValue(99))],
        },
      );
      expect(VaultProjection(ffi).decode(Uint8List(0), vaultKey), isEmpty);
    });
  });

  group('VaultDocWriter.putFields', () {
    test('chiffre chaque champ, HLC strictement croissant, création marquée', () {
      final ffi = _FakeCrdtFfi();
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
      final ffi = _FakeCrdtFfi();
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
