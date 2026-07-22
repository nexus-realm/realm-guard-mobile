import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/sync/crdt_ffi.dart';
import 'package:realmguard/core/sync/drift_projector.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';

import '../../support/sync_test_doubles.dart';

Uint8List _id(int fill) => Uint8List.fromList(List.filled(16, fill));

CrdtField _cf(int fieldId, FieldValue value) =>
    CrdtField(fieldId: fieldId, value: value.encode());

/// Construit un doc factice : un `FakeCrdtFfi` dont la lecture renvoie
/// exactement les entrées décrites (le (dé)chiffrement y est l'identité).
FakeCrdtFfi _doc(Map<Uint8List, List<CrdtField>> entries) => FakeCrdtFfi(
  ids: entries.keys.toList(),
  fieldsById: {
    for (final entry in entries.entries)
      FakeCrdtFfi.hex(entry.key): entry.value,
  },
);

List<CrdtField> _profile(String name) => [
  _cf(VaultFields.kind, IntValue(VaultKind.profile.code)),
  _cf(VaultFields.profileName, TextValue(name)),
];

List<CrdtField> _credential(String title, {Uint8List? profileRef}) => [
  _cf(VaultFields.kind, IntValue(VaultKind.credential.code)),
  _cf(VaultFields.credentialTitle, TextValue(title)),
  if (profileRef != null)
    _cf(VaultFields.credentialProfileId, UuidValue(profileRef)),
];

List<CrdtField> _totp(String label, {Uint8List? profileRef}) => [
  _cf(VaultFields.kind, IntValue(VaultKind.totp.code)),
  _cf(VaultFields.totpLabel, TextValue(label)),
  _cf(VaultFields.totpSecret, const TextValue('JBSWY3DPEHPK3PXP')),
  if (profileRef != null) _cf(VaultFields.totpProfileId, UuidValue(profileRef)),
];

/// Reprojection **doc CRDT → drift** sur une base en mémoire. Le doc est simulé
/// par [FakeCrdtFfi] (pas de lib native) ; ce qui est testé ici est l'effet réel
/// sur les tables drift : upsert par `syncId`, résolution des FK profil, et le
/// caractère **destructif** documenté (les lignes absentes du doc disparaissent).
void main() {
  late AppDatabase db;
  final vaultKey = Uint8List.fromList([1, 2, 3]);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<ReprojectionSummary> reproject(FakeCrdtFfi ffi) =>
      DriftProjector(db, ffi).reproject(Uint8List(0), vaultKey);

  group('Insertion', () {
    test('crée les lignes absentes des trois tables', () async {
      final summary = await reproject(
        _doc({
          _id(1): _profile('Perso'),
          _id(2): _credential('GitHub'),
          _id(3): _totp('GitLab'),
        }),
      );

      expect(summary.added, 3);
      expect(summary.updated, 0);
      expect(summary.removed, 0);
      expect(summary.changed, 3);

      expect((await db.select(db.profiles).get()).single.name, 'Perso');
      expect((await db.select(db.credentials).get()).single.title, 'GitHub');
      expect((await db.select(db.totps).get()).single.label, 'GitLab');
    });

    test('résout la FK profil (UUID du doc → id local)', () async {
      await reproject(
        _doc({
          _id(1): _profile('Perso'),
          _id(2): _credential('GitHub', profileRef: _id(1)),
          _id(3): _totp('GitLab', profileRef: _id(1)),
        }),
      );

      final profile = (await db.select(db.profiles).get()).single;
      expect(
        (await db.select(db.credentials).get()).single.profileId,
        profile.id,
      );
      expect((await db.select(db.totps).get()).single.profileId, profile.id);
    });

    test('une FK vers un profil absent du doc reste nulle', () async {
      await reproject(
        _doc({_id(2): _credential('GitHub', profileRef: _id(9))}),
      );

      expect((await db.select(db.credentials).get()).single.profileId, isNull);
    });
  });

  group('Idempotence', () {
    test('rejouer le même doc ne change rien', () async {
      final ffi = _doc({
        _id(1): _profile('Perso'),
        _id(2): _credential('GitHub', profileRef: _id(1)),
        _id(3): _totp('GitLab'),
      });

      expect((await reproject(ffi)).added, 3);

      // Second passage : les lignes identiques ne sont pas réécrites.
      final second = await reproject(ffi);
      expect(second.changed, 0);
      expect(second.added, 0);
      expect(second.updated, 0);
      expect(second.removed, 0);
    });
  });

  group('Mise à jour', () {
    test('un champ modifié met à jour la ligne sans changer son id', () async {
      await reproject(_doc({_id(2): _credential('Avant')}));
      final before = (await db.select(db.credentials).get()).single;

      final summary = await reproject(_doc({_id(2): _credential('Après')}));

      expect(summary.updated, 1);
      expect(summary.added, 0);
      final after = (await db.select(db.credentials).get()).single;
      expect(
        after.id,
        before.id,
        reason: 'upsert par syncId, pas ré-insertion',
      );
      expect(after.title, 'Après');
    });

    test('un profil renommé est mis à jour', () async {
      await reproject(_doc({_id(1): _profile('Avant')}));

      final summary = await reproject(_doc({_id(1): _profile('Après')}));

      expect(summary.updated, 1);
      expect((await db.select(db.profiles).get()).single.name, 'Après');
    });

    test('un TOTP re-libellé est mis à jour', () async {
      await reproject(_doc({_id(3): _totp('Avant')}));

      final summary = await reproject(_doc({_id(3): _totp('Après')}));

      expect(summary.updated, 1);
      expect((await db.select(db.totps).get()).single.label, 'Après');
    });

    test('un rattachement de profil est répercuté', () async {
      await reproject(
        _doc({_id(1): _profile('Perso'), _id(2): _credential('GitHub')}),
      );
      expect((await db.select(db.credentials).get()).single.profileId, isNull);

      final summary = await reproject(
        _doc({
          _id(1): _profile('Perso'),
          _id(2): _credential('GitHub', profileRef: _id(1)),
        }),
      );

      expect(summary.updated, 1);
      expect(
        (await db.select(db.credentials).get()).single.profileId,
        isNotNull,
      );
    });
  });

  group('Suppression (reprojection destructive)', () {
    test(
      'supprime les lignes dont le syncId n\'est plus dans le doc',
      () async {
        await reproject(
          _doc({
            _id(1): _profile('Perso'),
            _id(2): _credential('GitHub'),
            _id(3): _totp('GitLab'),
          }),
        );

        // Le doc ne contient plus que le credential.
        final summary = await reproject(_doc({_id(2): _credential('GitHub')}));

        expect(summary.removed, 2);
        expect(await db.select(db.profiles).get(), isEmpty);
        expect(await db.select(db.totps).get(), isEmpty);
        expect((await db.select(db.credentials).get()).single.title, 'GitHub');
      },
    );

    test('un doc vide vide la base', () async {
      await reproject(
        _doc({_id(1): _profile('Perso'), _id(2): _credential('GitHub')}),
      );

      final summary = await reproject(_doc({}));

      expect(summary.removed, 2);
      expect(await db.select(db.credentials).get(), isEmpty);
      expect(await db.select(db.profiles).get(), isEmpty);
    });

    test(
      'supprime aussi les lignes sans syncId (cas post-migration)',
      () async {
        await db
            .into(db.credentials)
            .insert(
              CredentialsCompanion.insert(
                title: 'orpheline',
              ).copyWith(syncId: const Value(null)),
            );

        final summary = await reproject(_doc({}));

        expect(summary.removed, 1);
        expect(await db.select(db.credentials).get(), isEmpty);
      },
    );
  });
}
