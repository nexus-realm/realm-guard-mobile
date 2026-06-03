import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/database/app_database.dart';
import 'package:realm_guard_mobile/core/database/vault_repository.dart';
import 'package:realm_guard_mobile/features/home/data/profile_deletion_strategy.dart';
import 'package:realm_guard_mobile/features/home/data/profile_draft.dart';
import 'package:realm_guard_mobile/features/home/viewmodels/profile_detail_view_model.dart';

class FakeProfileEditor implements ProfileEditor {
  final StreamController<Profile?> controller =
      StreamController<Profile?>.broadcast();
  int linkedCount = 0;

  int? updatedId;
  ProfileDraft? updatedDraft;
  int? deletedId;
  ProfileDeletionStrategy? deletedStrategy;

  @override
  Stream<Profile?> watchProfile(int id) => controller.stream;

  @override
  Future<bool> updateProfile(int id, ProfileDraft draft) async {
    updatedId = id;
    updatedDraft = draft;
    return true;
  }

  @override
  Future<int> countCredentialsForProfile(int profileId) async => linkedCount;

  @override
  Future<void> deleteProfile(int id, ProfileDeletionStrategy strategy) async {
    deletedId = id;
    deletedStrategy = strategy;
  }
}

Profile _profile(int id, String name, String emailsJson) => Profile(
  id: id,
  name: name,
  emails: emailsJson,
  usernames: '[]',
  phoneNumbers: '[]',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('ProfileDetailViewModel', () {
    test('décode les emails JSON de l\'enregistrement', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(_profile(1, 'Perso', '["a@b.com","c@d.com"]'));
      await _settle();

      expect(vm.current?.name, 'Perso');
      expect(vm.emails, ['a@b.com', 'c@d.com']);
    });

    test('emails vide si JSON corrompu', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(_profile(1, 'Perso', 'not-json'));
      await _settle();

      expect(vm.emails, isEmpty);
    });

    test('hasChanges compare nom et emails (vides ignorés)', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 1);
      addTearDown(vm.dispose);

      await vm.initialize();
      repo.controller.add(_profile(1, 'Perso', '["a@b.com"]'));
      await _settle();

      expect(
        vm.hasChanges(name: 'Perso', emails: ['a@b.com', '  ']),
        isFalse,
      );
      expect(vm.hasChanges(name: 'Pro', emails: ['a@b.com']), isTrue);
      expect(vm.hasChanges(name: 'Perso', emails: ['x@y.com']), isTrue);
    });

    test('save refuse un nom vide', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();

      final ok = await vm.save(name: '  ', emails: const []);

      expect(ok, isFalse);
      expect(repo.updatedId, isNull);
    });

    test('save met à jour en filtrant les emails vides', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 5);
      addTearDown(vm.dispose);
      await vm.initialize();
      vm.startEditing();

      final ok = await vm.save(
        name: '  Perso  ',
        emails: ['a@b.com', '', '  '],
      );

      expect(ok, isTrue);
      expect(repo.updatedId, 5);
      expect(repo.updatedDraft?.name, 'Perso');
      expect(repo.updatedDraft?.emails, ['a@b.com']);
      expect(vm.isEditing, isFalse);
    });

    test('linkedCredentialsCount délègue au dépôt', () async {
      final repo = FakeProfileEditor()..linkedCount = 3;
      final vm = ProfileDetailViewModel(repository: repo, profileId: 1);
      addTearDown(vm.dispose);

      expect(await vm.linkedCredentialsCount(), 3);
    });

    test('delete applique la stratégie choisie', () async {
      final repo = FakeProfileEditor();
      final vm = ProfileDetailViewModel(repository: repo, profileId: 8);
      addTearDown(vm.dispose);
      await vm.initialize();

      final ok = await vm.delete(ProfileDeletionStrategy.cascade);

      expect(ok, isTrue);
      expect(repo.deletedId, 8);
      expect(repo.deletedStrategy, ProfileDeletionStrategy.cascade);
      expect(vm.deleted, isTrue);
    });
  });
}
