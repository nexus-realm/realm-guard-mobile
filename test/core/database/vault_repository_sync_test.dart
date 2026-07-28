import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/database/vault_repository.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_crdt.dart';
import 'package:realmguard/core/sync/vault_fields.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';
import 'package:realmguard/features/home/data/profile_deletion_strategy.dart';
import 'package:realmguard/features/home/data/profile_draft.dart';
import 'package:realmguard/features/home/data/totp_draft.dart';

import '../../support/sync_test_doubles.dart';

/// Contrat **write-through** du dépôt : chaque mutation drift est répercutée
/// best-effort dans le doc CRDT. La base est réelle (en mémoire), le CRDT est
/// monté sur des doubles (FFI identité + stores en mémoire) — on observe donc
/// les vrais `setField` / `removeEntry` émis.
void main() {
  late AppDatabase db;
  late FakeCrdtFfi ffi;
  late VaultCrdt crdt;
  late VaultRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ffi = FakeCrdtFfi();
    crdt = VaultCrdt(
      ffi: ffi,
      store: InMemoryVaultDocStore(),
      pending: InMemoryPendingDeltaStore(),
      vaultKey: Uint8List.fromList([1, 2, 3]),
      deviceId: Uint8List.fromList(List.filled(16, 7)),
    );
    repository = VaultRepository(db, crdtSession: () async => crdt);
  });

  tearDown(() => db.close());

  /// Dernière valeur écrite pour [fieldId], décodée.
  FieldValue? lastField(int fieldId) {
    final calls = ffi.setFields.where((c) => c.fieldId == fieldId);
    return calls.isEmpty ? null : FieldValue.decode(calls.last.value);
  }

  group('Création', () {
    test('un profil ajouté est marqué présent et poussé dans le doc', () async {
      await repository.addProfile(const ProfileDraft(name: 'Perso'));

      expect(ffi.added, hasLength(1), reason: 'add_entry : entrée nouvelle');
      expect(lastField(VaultFields.kind), IntValue(VaultKind.profile.code));
      expect(lastField(VaultFields.profileName), const TextValue('Perso'));
    });

    test('l\'entryId CRDT est le syncId de la ligne drift', () async {
      final id = await repository.addProfile(const ProfileDraft(name: 'Perso'));

      final row = (await db.select(db.profiles).get()).single;
      expect(row.id, id);
      expect(ffi.added.single, row.syncId);
    });

    test('un credential ajouté est poussé avec ses champs', () async {
      await repository.addCredential(
        const CredentialDraft(title: 'GitHub', username: 'me'),
      );

      expect(lastField(VaultFields.kind), IntValue(VaultKind.credential.code));
      expect(lastField(VaultFields.credentialTitle), const TextValue('GitHub'));
      expect(lastField(VaultFields.credentialUsername), const TextValue('me'));
    });

    test('un TOTP ajouté est poussé avec son secret', () async {
      await repository.addTotp(
        const TotpDraft(label: 'GitLab', secret: 'JBSWY3DPEHPK3PXP'),
      );

      expect(lastField(VaultFields.kind), IntValue(VaultKind.totp.code));
      expect(lastField(VaultFields.totpLabel), const TextValue('GitLab'));
      expect(
        lastField(VaultFields.totpSecret),
        const TextValue('JBSWY3DPEHPK3PXP'),
      );
    });

    test('la FK profil est poussée en UUID, pas en id local', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      final profileSyncId = (await db.select(db.profiles).get()).single.syncId;

      await repository.addCredential(
        CredentialDraft(title: 'GitHub', profileId: profileId),
      );

      expect(
        lastField(VaultFields.credentialProfileId),
        UuidValue(profileSyncId!),
      );
    });
  });

  group('Modification', () {
    test(
      'une mise à jour repousse les champs sans re-marquer présent',
      () async {
        final id = await repository.addCredential(
          const CredentialDraft(title: 'Avant'),
        );
        final addedCount = ffi.added.length;

        await repository.updateCredential(
          id,
          const CredentialDraft(title: 'Après'),
        );

        expect(
          lastField(VaultFields.credentialTitle),
          const TextValue('Après'),
        );
        expect(ffi.added, hasLength(addedCount), reason: 'pas de nouvel add');
      },
    );

    test('un profil renommé est repoussé', () async {
      final id = await repository.addProfile(const ProfileDraft(name: 'Avant'));

      await repository.updateProfile(id, const ProfileDraft(name: 'Après'));

      expect(lastField(VaultFields.profileName), const TextValue('Après'));
    });

    test('un TOTP modifié est repoussé', () async {
      final id = await repository.addTotp(
        const TotpDraft(label: 'Avant', secret: 'JBSWY3DPEHPK3PXP'),
      );

      await repository.updateTotp(
        id,
        const TotpDraft(label: 'Après', secret: 'JBSWY3DPEHPK3PXP'),
      );

      expect(lastField(VaultFields.totpLabel), const TextValue('Après'));
    });
  });

  group('Suppression', () {
    test('supprimer un credential retire l\'entrée du doc', () async {
      final id = await repository.addCredential(
        const CredentialDraft(title: 'GitHub'),
      );
      final syncId = (await db.select(db.credentials).get()).single.syncId;

      await repository.deleteCredential(id);

      expect(ffi.removed.single, syncId);
    });

    test('supprimer un TOTP retire l\'entrée du doc', () async {
      final id = await repository.addTotp(
        const TotpDraft(label: 'GitLab', secret: 'JBSWY3DPEHPK3PXP'),
      );
      final syncId = (await db.select(db.totps).get()).single.syncId;

      await repository.deleteTotp(id);

      expect(ffi.removed.single, syncId);
    });

    test(
      'deleteProfile en cascade retire profil ET identifiants liés',
      () async {
        final profileId = await repository.addProfile(
          const ProfileDraft(name: 'Perso'),
        );
        await repository.addCredential(
          CredentialDraft(title: 'GitHub', profileId: profileId),
        );

        await repository.deleteProfile(
          profileId,
          ProfileDeletionStrategy.cascade,
        );

        // 2 retraits : le credential lié puis le profil lui-même.
        expect(ffi.removed, hasLength(2));
        expect(await db.select(db.credentials).get(), isEmpty);
        expect(await db.select(db.profiles).get(), isEmpty);
      },
    );

    test(
      'les TOTP liés ne sont pas touchés par la suppression du profil',
      () async {
        // Comportement **actuel** : `deleteProfile` ne considère que les
        // identifiants (les deux libellés du dialogue parlent d'« identifiants »).
        // Le TOTP survit donc avec une FK profil pendante — bénin (id jamais
        // réutilisé, `AUTOINCREMENT`) et rattrapé par la prochaine reprojection,
        // mais l'écart est réel : voir la note de suivi.
        final profileId = await repository.addProfile(
          const ProfileDraft(name: 'Perso'),
        );
        await repository.addTotp(
          TotpDraft(
            label: 'GitLab',
            secret: 'JBSWY3DPEHPK3PXP',
            profileId: profileId,
          ),
        );

        await repository.deleteProfile(
          profileId,
          ProfileDeletionStrategy.cascade,
        );

        final totp = (await db.select(db.totps).get()).single;
        expect(totp.profileId, profileId, reason: 'FK laissée pendante');
        expect(await db.select(db.profiles).get(), isEmpty);
      },
    );

    test('deleteProfile en dissociation ne retire que le profil', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(
        CredentialDraft(title: 'GitHub', profileId: profileId),
      );
      final profileSyncId = (await db.select(db.profiles).get()).single.syncId;

      await repository.deleteProfile(
        profileId,
        ProfileDeletionStrategy.dissociate,
      );

      expect(ffi.removed.single, profileSyncId);
      // Le credential survit, détaché, et sa FK vidée est repoussée.
      expect((await db.select(db.credentials).get()).single.profileId, isNull);
    });
  });

  group('Best-effort', () {
    test('une session CRDT absente n\'empêche pas l\'écriture drift', () async {
      final offline = VaultRepository(db, crdtSession: () async => null);

      final id = await offline.addCredential(
        const CredentialDraft(title: 'GitHub'),
      );

      expect((await db.select(db.credentials).get()).single.id, id);
      expect(ffi.setFields, isEmpty);
    });

    test(
      'une session CRDT en échec n\'empêche pas l\'écriture drift',
      () async {
        final failing = VaultRepository(
          db,
          crdtSession: () async => throw StateError('coffre indisponible'),
        );

        final id = await failing.addCredential(
          const CredentialDraft(title: 'GitHub'),
        );

        expect(
          (await db.select(db.credentials).get()).single.id,
          id,
          reason: 'l\'échec de synchro est avalé, la mutation drift tient',
        );
      },
    );
  });
}
