import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/database/vault_repository.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';
import 'package:realmguard/features/home/data/profile_deletion_strategy.dart';
import 'package:realmguard/features/home/data/profile_draft.dart';
import 'package:realmguard/features/home/data/totp_draft.dart';

/// Tests du dépôt sur une base **en mémoire** (`AppDatabase.forTesting`) : même
/// schéma et mêmes migrations que la prod, sans SQLCipher (indisponible sur le
/// VM Dart). Aucune session CRDT n'est injectée → le write-through est inactif,
/// on teste ici la couche drift seule.
void main() {
  late AppDatabase db;
  late VaultRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = VaultRepository(db);
  });

  tearDown(() => db.close());

  group('Profils', () {
    test('ajoute puis relit un profil', () async {
      final id = await repository.addProfile(
        const ProfileDraft(name: 'Perso', emails: ['a@b.c']),
      );

      final profiles = await repository.getAllProfiles();
      expect(profiles, hasLength(1));
      expect(profiles.single.id, id);
      expect(profiles.single.name, 'Perso');
    });

    test('met à jour un profil existant', () async {
      final id = await repository.addProfile(const ProfileDraft(name: 'Avant'));

      final updated = await repository.updateProfile(
        id,
        const ProfileDraft(name: 'Après'),
      );

      expect(updated, isTrue);
      expect((await repository.getAllProfiles()).single.name, 'Après');
    });

    test('watchProfile émet le profil courant', () async {
      final id = await repository.addProfile(const ProfileDraft(name: 'Perso'));

      await expectLater(
        repository.watchProfile(id),
        emits(isA<dynamic>().having((p) => p?.name, 'name', 'Perso')),
      );
    });
  });

  group('Invariant syncId', () {
    test('chaque ligne reçoit un syncId unique de 16 octets', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(const CredentialDraft(title: 'GitHub'));
      await repository.addTotp(
        const TotpDraft(label: 'GitHub', secret: 'JBSWY3DPEHPK3PXP'),
      );

      final profile = (await repository.getAllProfiles()).single;
      final credential = (await repository.getAllCredentials()).single;

      expect(profile.id, profileId);
      for (final syncId in [profile.syncId, credential.syncId]) {
        expect(syncId, isNotNull);
        expect(syncId!.length, 16, reason: 'syncId doit faire 16 octets');
      }
      // Deux entités distinctes ne doivent jamais partager un syncId.
      expect(profile.syncId, isNot(equals(credential.syncId)));
    });
  });

  group('Identifiants', () {
    test(
      'la jointure remonte le profil associé, ou null sans profil',
      () async {
        final profileId = await repository.addProfile(
          const ProfileDraft(name: 'Perso'),
        );
        await repository.addCredential(
          CredentialDraft(title: 'Avec profil', profileId: profileId),
        );
        await repository.addCredential(
          const CredentialDraft(title: 'Sans profil'),
        );

        final rows = await repository.getCredentialsWithProfiles();

        expect(rows, hasLength(2));
        final withProfile = rows.firstWhere(
          (r) => r.credential.title == 'Avec profil',
        );
        final without = rows.firstWhere(
          (r) => r.credential.title == 'Sans profil',
        );
        expect(withProfile.profile?.name, 'Perso');
        expect(without.profile, isNull);
      },
    );

    test('met à jour puis supprime un identifiant', () async {
      final id = await repository.addCredential(
        const CredentialDraft(title: 'Avant'),
      );

      expect(
        await repository.updateCredential(
          id,
          const CredentialDraft(title: 'Après'),
        ),
        isTrue,
      );
      expect((await repository.getAllCredentials()).single.title, 'Après');

      expect(await repository.deleteCredential(id), 1);
      expect(await repository.getAllCredentials(), isEmpty);
    });

    test('countCredentialsForProfile ne compte que le profil visé', () async {
      final a = await repository.addProfile(const ProfileDraft(name: 'A'));
      final b = await repository.addProfile(const ProfileDraft(name: 'B'));
      await repository.addCredential(
        CredentialDraft(title: 'a1', profileId: a),
      );
      await repository.addCredential(
        CredentialDraft(title: 'a2', profileId: a),
      );
      await repository.addCredential(
        CredentialDraft(title: 'b1', profileId: b),
      );

      expect(await repository.countCredentialsForProfile(a), 2);
      expect(await repository.countCredentialsForProfile(b), 1);
    });
  });

  group('Suppression de profil', () {
    test('dissociate : les identifiants survivent, détachés', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(
        CredentialDraft(title: 'GitHub', profileId: profileId),
      );

      await repository.deleteProfile(
        profileId,
        ProfileDeletionStrategy.dissociate,
      );

      expect(await repository.getAllProfiles(), isEmpty);
      final credentials = await repository.getAllCredentials();
      expect(credentials, hasLength(1));
      expect(credentials.single.profileId, isNull);
    });

    test('cascade : les identifiants liés sont supprimés', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(
        CredentialDraft(title: 'Lié', profileId: profileId),
      );
      await repository.addCredential(const CredentialDraft(title: 'Autonome'));

      await repository.deleteProfile(
        profileId,
        ProfileDeletionStrategy.cascade,
      );

      final credentials = await repository.getAllCredentials();
      expect(credentials, hasLength(1));
      expect(credentials.single.title, 'Autonome');
    });
  });

  group('TOTP', () {
    test('ajoute, met à jour puis supprime un TOTP', () async {
      final id = await repository.addTotp(
        const TotpDraft(label: 'Avant', secret: 'JBSWY3DPEHPK3PXP'),
      );

      expect(
        await repository.updateTotp(
          id,
          const TotpDraft(label: 'Après', secret: 'JBSWY3DPEHPK3PXP'),
        ),
        isTrue,
      );
      await expectLater(
        repository.watchTotp(id),
        emits(
          isA<TotpWithProfile>().having((t) => t.totp.label, 'label', 'Après'),
        ),
      );

      expect(await repository.deleteTotp(id), 1);
    });
  });

  group('Flux joints (entrée + profil)', () {
    test('watchCredentialsWithProfiles joint le profil rattaché', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(
        CredentialDraft(title: 'GitHub', profileId: profileId),
      );
      await repository.addCredential(const CredentialDraft(title: 'Orphelin'));

      final rows = await repository.watchCredentialsWithProfiles().first;

      expect(rows, hasLength(2));
      final joined = rows.firstWhere((r) => r.credential.title == 'GitHub');
      expect(joined.profile?.name, 'Perso');
      final alone = rows.firstWhere((r) => r.credential.title == 'Orphelin');
      expect(alone.profile, isNull);
    });

    test('watchTotpsWithProfiles joint le profil rattaché', () async {
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

      final rows = await repository.watchTotpsWithProfiles().first;

      expect(rows.single.totp.label, 'GitLab');
      expect(rows.single.profile?.name, 'Perso');
    });

    test('watchCredential émet null pour un id inconnu', () async {
      expect(await repository.watchCredential(404).first, isNull);
    });

    test('watchTotp émet null pour un id inconnu', () async {
      expect(await repository.watchTotp(404).first, isNull);
    });
  });

  group('Flux par profil', () {
    test('watchCredentialsForProfile ne renvoie que les liés', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addCredential(
        CredentialDraft(title: 'Lié', profileId: profileId),
      );
      await repository.addCredential(const CredentialDraft(title: 'Libre'));

      final rows = await repository.watchCredentialsForProfile(profileId).first;

      expect(rows.single.title, 'Lié');
    });

    test('watchTotpsForProfile ne renvoie que les liés', () async {
      final profileId = await repository.addProfile(
        const ProfileDraft(name: 'Perso'),
      );
      await repository.addTotp(
        TotpDraft(
          label: 'Lié',
          secret: 'JBSWY3DPEHPK3PXP',
          profileId: profileId,
        ),
      );
      await repository.addTotp(
        const TotpDraft(label: 'Libre', secret: 'JBSWY3DPEHPK3PXP'),
      );

      final rows = await repository.watchTotpsForProfile(profileId).first;

      expect(rows.single.label, 'Lié');
    });

    test('watchAllProfiles émet la liste courante', () async {
      await repository.addProfile(const ProfileDraft(name: 'Perso'));
      await repository.addProfile(const ProfileDraft(name: 'Pro'));

      final rows = await repository.watchAllProfiles().first;

      expect(rows.map((p) => p.name), containsAll(['Perso', 'Pro']));
    });
  });
}
