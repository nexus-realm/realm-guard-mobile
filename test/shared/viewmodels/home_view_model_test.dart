import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/database/app_database.dart';
import 'package:realm_guard_mobile/core/database/vault_repository.dart';
import 'package:realm_guard_mobile/shared/notifiers/search_notifier.dart';
import 'package:realm_guard_mobile/shared/viewmodels/home_view_model.dart';

class FakeHomeRepository implements HomeRepository {
  final StreamController<List<Profile>> profiles =
      StreamController<List<Profile>>.broadcast();
  final StreamController<List<CredentialWithProfile>> credentials =
      StreamController<List<CredentialWithProfile>>.broadcast();

  @override
  Stream<List<Profile>> watchAllProfiles() => profiles.stream;

  @override
  Stream<List<CredentialWithProfile>> watchCredentialsWithProfiles() =>
      credentials.stream;
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

CredentialWithProfile _credential(
  int id,
  String title, {
  String? username,
  String? uri,
}) => CredentialWithProfile(
  Credential(
    id: id,
    title: title,
    username: username,
    uri: uri,
    customFields: '[]',
    favorite: false,
    profileId: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  null,
);

// Laisse tourner les microtasks pour que les listeners de stream s'exécutent.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('HomeViewModel', () {
    test('isLoading reste vrai tant que les deux flux n\'ont pas émis', () async {
      final repo = FakeHomeRepository();
      final vm = HomeViewModel(SearchNotifier(), repo);
      addTearDown(vm.dispose);

      // Aucune émission : chargement en cours.
      expect(vm.isLoading, isTrue);

      // Un seul flux a émis : toujours en chargement.
      repo.profiles.add([_profile(1, 'GitHub')]);
      await _settle();
      expect(vm.isLoading, isTrue);

      // Les deux flux ont émis : chargement terminé.
      repo.credentials.add(const []);
      await _settle();
      expect(vm.isLoading, isFalse);
    });

    test('isLoading se termine même pour un coffre vide', () async {
      final repo = FakeHomeRepository();
      final vm = HomeViewModel(SearchNotifier(), repo);
      addTearDown(vm.dispose);

      repo.profiles.add(const []);
      repo.credentials.add(const []);
      await _settle();

      expect(vm.isLoading, isFalse);
      expect(vm.results, isEmpty);
      expect(vm.hasSearchQuery, isFalse);
    });

    test('hasSearchQuery reflète la requête de recherche', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(
        search,
        repo,
        searchDebounce: const Duration(milliseconds: 10),
      );
      addTearDown(vm.dispose);

      repo.profiles.add(const []);
      repo.credentials.add(const []);
      await _settle();
      expect(vm.hasSearchQuery, isFalse);

      search.updateQuery('git');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(vm.hasSearchQuery, isTrue);
    });

    test('expose profils et credentials émis par les flux réactifs', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(search, repo);
      addTearDown(vm.dispose);

      repo.profiles.add([_profile(1, 'GitHub')]);
      repo.credentials.add([_credential(10, 'Gmail')]);
      await _settle();

      expect(vm.results.whereType<Profile>().length, 1);
      expect(vm.results.whereType<CredentialWithProfile>().length, 1);
    });

    test('se met à jour quand un flux ré-émet (réactivité)', () async {
      final repo = FakeHomeRepository();
      final vm = HomeViewModel(SearchNotifier(), repo);
      addTearDown(vm.dispose);

      repo.profiles.add([_profile(1, 'GitHub')]);
      await _settle();
      expect(vm.results.length, 1);

      // Une nouvelle émission (ex: après un ajout) rafraîchit la liste.
      repo.profiles.add([_profile(1, 'GitHub'), _profile(2, 'GitLab')]);
      await _settle();
      expect(vm.results.length, 2);
    });

    test('expose des listes filtrées séparées par type', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(
        search,
        repo,
        searchDebounce: const Duration(milliseconds: 20),
      );
      addTearDown(vm.dispose);

      repo.profiles.add([_profile(1, 'GitHub'), _profile(2, 'GitLab')]);
      repo.credentials.add([_credential(10, 'Gmail')]);
      await _settle();

      expect(vm.filteredProfiles, hasLength(2));
      expect(vm.filteredCredentials, hasLength(1));

      // La recherche filtre chaque liste indépendamment.
      search.updateQuery('lab');
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(vm.filteredProfiles.map((p) => p.name), ['GitLab']);
      expect(vm.filteredCredentials, isEmpty);
    });

    test('la recherche d\'identifiant porte sur titre, username et url', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(
        search,
        repo,
        searchDebounce: const Duration(milliseconds: 10),
      );
      addTearDown(vm.dispose);

      repo.profiles.add(const []);
      repo.credentials.add([
        _credential(1, 'GitHub', username: 'octocat'),
        _credential(2, 'Mail', uri: 'https://gmail.com'),
        _credential(3, 'Autre'),
      ]);
      await _settle();

      // Match sur username.
      search.updateQuery('octo');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(vm.filteredCredentials.map((c) => c.credential.title), ['GitHub']);

      // Match sur l'url.
      search.updateQuery('gmail');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(vm.filteredCredentials.map((c) => c.credential.title), ['Mail']);
    });

    test('filtre par requête de recherche', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(
        search,
        repo,
        searchDebounce: const Duration(milliseconds: 20),
      );
      addTearDown(vm.dispose);

      repo.profiles.add([_profile(1, 'GitHub'), _profile(2, 'GitLab')]);
      repo.credentials.add([_credential(10, 'Gmail')]);
      await _settle();

      search.updateQuery('lab');
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(vm.results.length, 1);
      expect((vm.results.first as Profile).name, 'GitLab');
    });

    test('debounce : seule la dernière requête rapide est appliquée', () async {
      final repo = FakeHomeRepository();
      final search = SearchNotifier();
      final vm = HomeViewModel(
        search,
        repo,
        searchDebounce: const Duration(milliseconds: 50),
      );
      addTearDown(vm.dispose);

      repo.profiles.add([_profile(1, 'GitHub'), _profile(2, 'GitLab')]);
      await _settle();

      // Frappes rapprochées : aucune ne doit s'appliquer avant la pause finale.
      search.updateQuery('g');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      search.updateQuery('git');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      search.updateQuery('gitlab');

      // Avant l'échéance du debounce : toujours les 2 résultats initiaux.
      expect(vm.results.length, 2);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(vm.results.length, 1);
      expect((vm.results.first as Profile).name, 'GitLab');
    });
  });
}
