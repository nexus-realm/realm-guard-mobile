import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/database/app_database.dart';
import 'package:realm_guard_mobile/core/database/vault_repository.dart';
import 'package:realm_guard_mobile/features/home/viewmodels/add_credential_view_model.dart';
import 'package:realm_guard_mobile/features/home/viewmodels/add_profile_view_model.dart';

class FakeVaultEditor implements VaultEditor {
  bool shouldThrow = false;
  List<Profile> profilesToReturn = const [];

  String? lastProfileName;
  List<String>? lastProfileEmails;
  String? lastCredentialTitle;
  String? lastCredentialData;
  int? lastCredentialProfileId;

  @override
  Future<List<Profile>> getAllProfiles() async => profilesToReturn;

  @override
  Future<int> addProfile(String name, List<String> emails) async {
    if (shouldThrow) throw Exception('db error');
    lastProfileName = name;
    lastProfileEmails = emails;
    return 1;
  }

  @override
  Future<int> addCredential(
    String title,
    String encryptedData,
    int? profileId,
  ) async {
    if (shouldThrow) throw Exception('db error');
    lastCredentialTitle = title;
    lastCredentialData = encryptedData;
    lastCredentialProfileId = profileId;
    return 1;
  }
}

void main() {
  group('AddProfileViewModel', () {
    test('refuse un nom vide sans appeler le dépôt', () async {
      final editor = FakeVaultEditor();
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit('   ', ['a@b.com']);

      expect(ok, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(editor.lastProfileName, isNull);
    });

    test('enregistre le profil en filtrant les emails vides', () async {
      final editor = FakeVaultEditor();
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit('  Perso  ', ['a@b.com', '  ', '']);

      expect(ok, isTrue);
      expect(editor.lastProfileName, 'Perso'); // trimmé
      expect(editor.lastProfileEmails, ['a@b.com']); // vides filtrés
      expect(vm.isSubmitting, isFalse);
    });

    test('signale une erreur si le dépôt échoue', () async {
      final editor = FakeVaultEditor()..shouldThrow = true;
      final vm = AddProfileViewModel(editor);

      final ok = await vm.submit('Perso', const []);

      expect(ok, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isSubmitting, isFalse);
    });
  });

  group('AddCredentialViewModel', () {
    test('initialize charge les profils', () async {
      final editor = FakeVaultEditor()
        ..profilesToReturn = [
          const Profile(id: 1, name: 'Perso', emails: '[]'),
        ];
      final vm = AddCredentialViewModel(editor);

      await vm.initialize();

      expect(vm.isLoading, isFalse);
      expect(vm.profiles, hasLength(1));
    });

    test('refuse un titre vide sans appeler le dépôt', () async {
      final editor = FakeVaultEditor();
      final vm = AddCredentialViewModel(editor);

      final ok = await vm.submit(title: '  ', data: 'secret', profileId: null);

      expect(ok, isFalse);
      expect(editor.lastCredentialTitle, isNull);
    });

    test('enregistre l\'identifiant avec le profil associé', () async {
      final editor = FakeVaultEditor();
      final vm = AddCredentialViewModel(editor);

      final ok = await vm.submit(
        title: '  GitHub  ',
        data: 'token',
        profileId: 7,
      );

      expect(ok, isTrue);
      expect(editor.lastCredentialTitle, 'GitHub'); // trimmé
      expect(editor.lastCredentialData, 'token');
      expect(editor.lastCredentialProfileId, 7);
    });
  });
}
