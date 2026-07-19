import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/database/vault_repository.dart';
import 'package:realmguard/features/home/data/totp_draft.dart';
import 'package:realmguard/features/home/viewmodels/add_totp_view_model.dart';
import 'package:realmguard/features/home/viewmodels/totp_detail_view_model.dart';

class FakeTotpEditor implements TotpEditor {
  final StreamController<TotpWithProfile?> controller =
      StreamController<TotpWithProfile?>.broadcast();
  List<Profile> profilesToReturn = const [];

  TotpDraft? addedDraft;
  int? updatedId;
  TotpDraft? updatedDraft;
  int? deletedId;

  @override
  Future<List<Profile>> getAllProfiles() async => profilesToReturn;

  @override
  Future<int> addTotp(TotpDraft draft) async {
    addedDraft = draft;
    return 1;
  }

  @override
  Stream<TotpWithProfile?> watchTotp(int id) => controller.stream;

  @override
  Future<bool> updateTotp(int id, TotpDraft draft) async {
    updatedId = id;
    updatedDraft = draft;
    return true;
  }

  @override
  Future<int> deleteTotp(int id) async {
    deletedId = id;
    return 1;
  }
}

const _validSecret = 'JBSWY3DPEHPK3PXP';

TotpWithProfile _totp(
  int id,
  String label, {
  String secret = _validSecret,
  int? profileId,
}) => TotpWithProfile(
  Totp(
    id: id,
    label: label,
    secret: secret,
    digits: 6,
    period: 30,
    algorithm: 'SHA1',
    favorite: false,
    profileId: profileId,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  null,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('AddTotpViewModel', () {
    test('refuse un libellé vide', () async {
      final repo = FakeTotpEditor();
      final vm = AddTotpViewModel(repo);
      final ok = await vm.submit(
        const TotpDraft(label: '  ', secret: _validSecret),
      );
      expect(ok, isFalse);
      expect(repo.addedDraft, isNull);
    });

    test('refuse un secret Base32 invalide', () async {
      final repo = FakeTotpEditor();
      final vm = AddTotpViewModel(repo);
      final ok = await vm.submit(
        const TotpDraft(label: 'GitHub', secret: '1189!!'),
      );
      expect(ok, isFalse);
      expect(repo.addedDraft, isNull);
      expect(vm.errorMessage, contains('Base32'));
    });

    test('enregistre un TOTP valide', () async {
      final repo = FakeTotpEditor();
      final vm = AddTotpViewModel(repo);
      final ok = await vm.submit(
        const TotpDraft(label: 'GitHub', secret: _validSecret, account: 'me'),
      );
      expect(ok, isTrue);
      expect(repo.addedDraft?.label, 'GitHub');
      expect(repo.addedDraft?.account, 'me');
    });
  });

  group('TotpDetailViewModel', () {
    test('charge le TOTP via le flux', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(1, 'GitHub'));
      await _settle();
      expect(vm.current?.totp.label, 'GitHub');
      expect(vm.notFound, isFalse);
    });

    test('notFound quand le flux émet null', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(null);
      await _settle();
      expect(vm.notFound, isTrue);
    });

    test('hasChanges détecte une modification', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 1);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(1, 'GitHub'));
      await _settle();

      expect(
        vm.hasChanges(const TotpDraft(label: 'GitHub', secret: _validSecret)),
        isFalse,
      );
      expect(
        vm.hasChanges(const TotpDraft(label: 'GitLab', secret: _validSecret)),
        isTrue,
      );
    });

    test('save met à jour', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 7);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(7, 'GitHub'));
      await _settle();

      final ok = await vm.save(
        const TotpDraft(label: 'GitLab', secret: _validSecret),
      );
      expect(ok, isTrue);
      expect(repo.updatedId, 7);
      expect(repo.updatedDraft?.label, 'GitLab');
      expect(vm.isEditing, isFalse);
    });

    test('delete marque supprimé', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 9);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(9, 'GitHub'));
      await _settle();

      final ok = await vm.delete();
      expect(ok, isTrue);
      expect(repo.deletedId, 9);
      expect(vm.deleted, isTrue);
    });

    test('setProfile enregistre le profil choisi', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(4, 'GitHub'));
      await _settle();

      final ok = await vm.setProfile(9);

      expect(ok, isTrue);
      expect(repo.updatedDraft?.profileId, 9);
    });

    test('setProfile à null dissocie le profil', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(4, 'GitHub', profileId: 3));
      await _settle();

      final ok = await vm.setProfile(null);

      expect(ok, isTrue);
      expect(repo.updatedDraft?.profileId, isNull);
    });

    test('setProfile sans changement n\'appelle pas le dépôt', () async {
      final repo = FakeTotpEditor();
      final vm = TotpDetailViewModel(repository: repo, totpId: 4);
      addTearDown(vm.dispose);
      await vm.initialize();
      repo.controller.add(_totp(4, 'GitHub', profileId: 3));
      await _settle();

      final ok = await vm.setProfile(3); // déjà ce profil

      expect(ok, isTrue);
      expect(repo.updatedDraft, isNull);
    });
  });
}
