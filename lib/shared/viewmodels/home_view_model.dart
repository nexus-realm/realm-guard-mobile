import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/database/vault_repository.dart';
import '../../core/routes/app_routes.dart';
import '../notifiers/search_notifier.dart';

class HomeViewModel extends ChangeNotifier {
  final SearchNotifier _searchNotifier;
  final HomeRepository _vaultRepository;
  final Duration _searchDebounce;

  List<Profile> _profiles = [];
  List<CredentialWithProfile> _credentials = [];
  String _query = '';

  // Le chargement est terminé quand les DEUX flux ont émis au moins une fois ;
  // évite d'afficher l'état "vide" pendant le chargement initial.
  bool _profilesLoaded = false;
  bool _credentialsLoaded = false;

  Timer? _debounceTimer;
  StreamSubscription<List<Profile>>? _profilesSub;
  StreamSubscription<List<CredentialWithProfile>>? _credentialsSub;

  final List<dynamic> _results = [];
  List<dynamic> get results => _results;

  // Listes filtrées par type, alimentées par la requête de recherche courante.
  List<Profile> _filteredProfiles = const [];
  List<CredentialWithProfile> _filteredCredentials = const [];

  /// Profils correspondant à la recherche courante (pour l'onglet Profils).
  List<Profile> get filteredProfiles => _filteredProfiles;

  /// Identifiants correspondant à la recherche courante (onglet Identifiants).
  List<CredentialWithProfile> get filteredCredentials => _filteredCredentials;

  /// Vrai tant que le premier chargement des données n'est pas terminé.
  bool get isLoading => !(_profilesLoaded && _credentialsLoaded);

  /// Vrai si une recherche est active (permet de distinguer "coffre vide" de
  /// "aucun résultat de recherche").
  bool get hasSearchQuery => _query.isNotEmpty;

  HomeViewModel(
    this._searchNotifier,
    this._vaultRepository, {
    Duration searchDebounce = const Duration(milliseconds: 250),
  }) : _searchDebounce = searchDebounce {
    _query = _searchNotifier.query.trim().toLowerCase();
    _searchNotifier.addListener(_onSearchChanged);

    // Flux Drift réactifs : la liste se met à jour automatiquement après tout
    // ajout / édition / suppression dans le coffre.
    _profilesSub = _vaultRepository.watchAllProfiles().listen((profiles) {
      _profiles = profiles;
      _profilesLoaded = true;
      _rebuildResults();
    });
    _credentialsSub = _vaultRepository.watchCredentialsWithProfiles().listen((
      credentials,
    ) {
      _credentials = credentials;
      _credentialsLoaded = true;
      _rebuildResults();
    });
  }

  void _onSearchChanged() {
    // Debounce : on ne refiltre qu'après une courte pause de saisie.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      _query = _searchNotifier.query.trim().toLowerCase();
      _rebuildResults();
    });
  }

  void _rebuildResults() {
    _filteredProfiles = _profiles
        .where((p) => p.name.toLowerCase().contains(_query))
        .toList();
    _filteredCredentials = _credentials
        .where((c) => _matchesCredential(c.credential))
        .toList();

    _results
      ..clear()
      ..addAll(_filteredProfiles)
      ..addAll(_filteredCredentials);
    notifyListeners();
  }

  /// La recherche d'un identifiant porte sur le titre, le nom d'utilisateur et
  /// l'URL.
  bool _matchesCredential(Credential c) {
    if (_query.isEmpty) return true;
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(_query);
    return contains(c.title) || contains(c.username) || contains(c.uri);
  }

  /// Ouvre le menu d'ajout dans une bottom sheet **modale**.
  ///
  /// `useRootNavigator: true` est indispensable : le FAB qui déclenche ce menu
  /// vit dans le `Scaffold` de `HomeShell`, AU-DESSUS du Navigator imbriqué du
  /// `ShellRoute` (celui qui héberge `HomeTab`). Sans ce flag, la sheet serait
  /// poussée sur ce Navigator imbriqué et sa barrière ne couvrirait que le
  /// `body` : le FAB resterait visible ET cliquable, permettant d'empiler
  /// plusieurs sheets. En poussant sur le Navigator racine, la barrière couvre
  /// tout l'écran (FAB compris) → une seule sheet à la fois, pas d'empilement.
  ///
  /// La sheet n'ajoute pas d'entrée d'historique (pas de bouton retour parasite
  /// dans l'AppBar).
  Future<void> openAddBottomSheet(BuildContext context) async {
    if (!context.mounted) return;

    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ajouter au coffre',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter un profil'),
              onTap: () => Navigator.of(sheetContext).pop(_AddAction.profile),
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Ajouter un identifiant'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AddAction.credential),
            ),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case _AddAction.profile:
        context.push(AppRoutes.addProfile);
      case _AddAction.credential:
        context.push(AppRoutes.addCredential);
    }
  }

  /// Navigation directe vers l'ajout d'un identifiant (FAB de l'onglet
  /// Identifiants).
  void addCredential(BuildContext context) =>
      context.push(AppRoutes.addCredential);

  /// Navigation directe vers l'ajout d'un profil (FAB de l'onglet Profils).
  void addProfile(BuildContext context) => context.push(AppRoutes.addProfile);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _profilesSub?.cancel();
    _credentialsSub?.cancel();
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}

/// Action choisie dans la bottom sheet d'ajout.
enum _AddAction { profile, credential }
