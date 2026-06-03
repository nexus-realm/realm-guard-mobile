import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/database/app_database.dart';
import 'package:realm_guard_mobile/core/database/vault_repository.dart';
import 'package:realm_guard_mobile/features/home/viewmodels/credential_detail_view_model.dart';

class FakeCredentialEditor implements CredentialEditor {
  final StreamController<CredentialWithProfile?> controller =
      StreamController<CredentialWithProfile?>.broadcast();
  List<Profile> profilesToReturn = const [];

  int? updatedId;
  String? updatedTitle;
  String? updatedData;
  int? updatedProfileId;
  int? deletedId;
  bool throwOnUpdate = false;

  @override
  Stream<CredentialWithProfile?> watchCredential(int id) => controller.stream;

  @override
  Future<List<Profile>> getAllProfiles() async => profilesToReturn;

  @override
  Future<bool> updateCredential(
    int id,
    String title,
    String encryptedData,
    int? profileId,
  ) async {
    if (throwOnUpdate) throw Exception('db');
    updatedId = id;
    updatedTitle = title;
    updatedData = encryptedData;
    updatedProfileId = profileId;
    return true;
  }

  @override
  Future<int> deleteCredential(int id) async {
    deletedId = id;
    return 1;
  }
}

CredentialWithProfile _cred(
  int id,
  String title, {
  String data = '',
  int? profileId,
}) => CredentialWithProfile(
  Credential(id: id, title: title, encryptedData: data, profileId: profileId),
  null,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CredentialDetailViewModel', () {
    test('charge l\'identifiant via le flux réactif', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(_cred(1, 'GitHub'));
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
      repo.controller.add(_cred(1, 'GitHub', data: 'token', profileId: 2));
      await _settle();

      expect(
        vm.hasChanges(title: 'GitHub', data: 'token', profileId: 2),
        isFalse,
      );
      expect(
        vm.hasChanges(title: 'GitLab', data: 'token', profileId: 2),
        isTrue,
      );
      expect(
        vm.hasChanges(title: 'GitHub', data: 'token', profileId: null),
        isTrue,
      );
    });

    test('save refuse un titre vide', () async {
      final repo = FakeCredentialEditor();
      final vm = CredentialDetailViewModel(repository: repo, credentialId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();

      final ok = await vm.save(title: '   ', data: 'x', profileId: null);

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

      final ok = await vm.save(title: '  GitHub  ', data: 'tok', profileId: 3);

      expect(ok, isTrue);
      expect(repo.updatedId, 7);
      expect(repo.updatedTitle, 'GitHub'); // trimmé
      expect(repo.updatedProfileId, 3);
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
  });
}
