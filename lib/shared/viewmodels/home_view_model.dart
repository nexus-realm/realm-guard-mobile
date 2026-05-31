import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/database/vault_repository.dart';
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

  /// Vrai tant que le premier chargement des données n'est pas terminé.
  bool get isLoading => !(_profilesLoaded && _credentialsLoaded);

  /// Vrai si une recherche est active (permet de distinguer "coffre vide" de
  /// "aucun résultat de recherche").
  bool get hasSearchQuery => _query.isNotEmpty;

  PersistentBottomSheetController? _controller;
  bool get isBottomSheetOpen => _controller != null;

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
    _results
      ..clear()
      ..addAll(_profiles.where((p) => p.name.toLowerCase().contains(_query)))
      ..addAll(
        _credentials.where(
          (c) => c.credential.title.toLowerCase().contains(_query),
        ),
      );
    notifyListeners();
  }

  void openAddBottomSheet(BuildContext context) {
    if (!context.mounted) return;

    if (isBottomSheetOpen) {
      closeBottomSheet();
      return;
    }

    _controller = Scaffold.of(context).showBottomSheet(
      (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter un profil'),
              onTap: () {
                Navigator.of(context).pop();
                _addProfile(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Ajouter une crédential'),
              onTap: () {
                Navigator.of(context).pop();
                _addCredential(context);
              },
            ),
          ],
        ),
      ),
    );

    notifyListeners();

    _controller!.closed.then((_) {
      _controller = null;
      notifyListeners();
    });
  }

  void closeBottomSheet() {
    _controller?.close();
    _controller = null;

    notifyListeners();
  }

  void _addProfile(BuildContext context) {

  }

  void _addCredential(BuildContext context) {

  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _profilesSub?.cancel();
    _credentialsSub?.cancel();
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}
