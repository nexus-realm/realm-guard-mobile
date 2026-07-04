import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/database/vault_repository.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';
import 'package:realmguard/features/home/data/profile_draft.dart';
import 'package:realmguard/features/home/viewmodels/add_credential_view_model.dart';
import 'package:realmguard/features/home/viewmodels/add_profile_view_model.dart';

class FakeVaultEditor implements VaultEditor {
  bool shouldThrow = false;
  List<Profile> profilesToReturn = const [];

  ProfileDraft? lastProfileDraft;
  CredentialDraft? lastCredentialDraft;

  @override
  Future<List<Profile>> getAllProfiles() async => profilesToReturn;

  @override
  Future<int> addProfile(ProfileDraft draft) async {
    if (shouldThrow) throw Exception('db error');
    lastProfileDraft = draft;
    return 1;
  }

  @override
  Future<int> addCredential(CredentialDraft draft) async {
    if (shouldThrow) throw Exception('db error');
    lastCredentialDraft = draft;
    return 1;
  }
}

void main() {
  group('AddProfileViewModel', () {
    test('refuse un nom vide sans appeler le dépôt', () async {
      final editor = FakeVaultEditor();
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit(const ProfileDraft(name: '   '));

      expect(ok, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(editor.lastProfileDraft, isNull);
    });

    test('enregistre le profil', () async {
      final editor = FakeVaultEditor();
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit(
        const ProfileDraft(name: 'Perso', emails: ['a@b.com']),
      );

      expect(ok, isTrue);
      expect(editor.lastProfileDraft?.name, 'Perso');
      expect(editor.lastProfileDraft?.emails, ['a@b.com']);
      expect(vm.isSubmitting, isFalse);
    });

    test('signale une erreur si le dépôt échoue', () async {
      final editor = FakeVaultEditor()..shouldThrow = true;
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit(const ProfileDraft(name: 'Perso'));

      expect(ok, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isSubmitting, isFalse);
    });
  });

  group('AddCredentialViewModel', () {
    test('initialize charge les profils', () async {
      final editor = FakeVaultEditor()
        ..profilesToReturn = [_profile(1, 'Perso')];
      final vm = AddCredentialViewModel(editor);

      await vm.initialize();

      expect(vm.isLoading, isFalse);
      expect(vm.profiles, hasLength(1));
    });

    test('refuse un titre vide sans appeler le dépôt', () async {
      final editor = FakeVaultEditor();
      final vm = AddCredentialViewModel(editor);

      final ok = await vm.submit(
        const CredentialDraft(title: '  ', notes: 'secret'),
      );

      expect(ok, isFalse);
      expect(editor.lastCredentialDraft, isNull);
    });

    test('enregistre l\'identifiant avec le profil associé', () async {
      final editor = FakeVaultEditor();
      final vm = AddCredentialViewModel(editor);

      final ok = await vm.submit(
        const CredentialDraft(title: 'GitHub', notes: 'token', profileId: 7),
      );

      expect(ok, isTrue);
      expect(editor.lastCredentialDraft?.title, 'GitHub');
      expect(editor.lastCredentialDraft?.notes, 'token');
      expect(editor.lastCredentialDraft?.profileId, 7);
    });
  });
}

Profile _profile(int id, String name) => Profile(
  id: id,
  name: name,
  emails: '[]',
  usernames: '[]',
  phoneNumbers: '[]',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
