import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';
import 'package:realmguard/features/home/viewmodels/credential_detail_view_model.dart';

import '../../../support/home_test_doubles.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CredentialDetailViewModel', () {
    test('charge l\'identifiant via le flux réactif', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(credentialWithProfile(1, 'GitHub'));
      await _settle();

      expect(vm.isLoading, isFalse);
      expect(vm.current?.credential.title, 'GitHub');
      expect(vm.notFound, isFalse);
    });

    test('notFound quand le flux émet null', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(null);
      await _settle();

      expect(vm.notFound, isTrue);
    });

    test('hasChanges détecte les écarts avec l\'enregistrement', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(
        credentialWithProfile(1, 'GitHub', notes: 'token', profileId: 2),
      );
      await _settle();

      expect(
        vm.hasChanges(
          const CredentialDraft(title: 'GitHub', notes: 'token', profileId: 2),
        ),
        isFalse,
      );
      expect(
        vm.hasChanges(
          const CredentialDraft(title: 'GitLab', notes: 'token', profileId: 2),
        ),
        isTrue,
      );
      expect(
        vm.hasChanges(const CredentialDraft(title: 'GitHub', notes: 'token')),
        isTrue,
      );
    });

    test('save refuse un titre vide', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();

      final ok = await vm.save(const CredentialDraft(title: '   ', notes: 'x'));

      expect(ok, isFalse);
      expect(repo.updatedId, isNull);
      expect(vm.errorMessage, isNotNull);
    });

    test('save met à jour et sort du mode édition', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 7);
      addTearDown(vm.dispose);
      await vm.initialize();
      vm.startEditing();

      final ok = await vm.save(
        const CredentialDraft(title: 'GitHub', notes: 'tok', profileId: 3),
      );

      expect(ok, isTrue);
      expect(repo.updatedId, 7);
      expect(repo.updatedDraft?.title, 'GitHub');
      expect(repo.updatedDraft?.profileId, 3);
      expect(vm.isEditing, isFalse);
    });

    test('delete marque l\'élément supprimé', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 9);
      addTearDown(vm.dispose);
      await vm.initialize();

      final ok = await vm.delete();

      expect(ok, isTrue);
      expect(repo.deletedId, 9);
      expect(vm.deleted, isTrue);
    });

    test('hasChanges détecte les champs enrichis', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(
        credentialWithProfile(1, 'GitHub', username: 'me', password: 'pw'),
      );
      await _settle();

      expect(
        vm.hasChanges(
          const CredentialDraft(
            title: 'GitHub',
            username: 'me',
            password: 'pw',
          ),
        ),
        isFalse,
      );
      // Changement de mot de passe détecté.
      expect(
        vm.hasChanges(
          const CredentialDraft(
            title: 'GitHub',
            username: 'me',
            password: 'new',
          ),
        ),
        isTrue,
      );
      // Passage en favori détecté.
      expect(
        vm.hasChanges(
          const CredentialDraft(
            title: 'GitHub',
            username: 'me',
            password: 'pw',
            favorite: true,
          ),
        ),
        isTrue,
      );
    });

    test('toggleFavorite enregistre l\'état inversé', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(credentialWithProfile(4, 'GitHub', favorite: false));
      await _settle();

      await vm.toggleFavorite();

      expect(repo.updatedDraft?.favorite, isTrue);
    });

    test('setProfile enregistre le profil choisi', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(credentialWithProfile(4, 'GitHub'));
      await _settle();

      final ok = await vm.setProfile(9);

      expect(ok, isTrue);
      expect(repo.updatedDraft?.profileId, 9);
    });

    test('setProfile à null dissocie le profil', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(credentialWithProfile(4, 'GitHub', profileId: 3));
      await _settle();

      final ok = await vm.setProfile(null);

      expect(ok, isTrue);
      expect(repo.updatedDraft?.profileId, isNull);
    });

    test('setProfile sans changement n\'appelle pas le dépôt', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(credentialWithProfile(4, 'GitHub', profileId: 3));
      await _settle();

      final ok = await vm.setProfile(3); // déjà ce profil

      expect(ok, isTrue);
      expect(repo.updatedDraft, isNull);
    });
  });
}
