import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/database/vault_repository.dart';
import '../notifiers/search_notifier.dart';

class HomeViewModel extends ChangeNotifier {
  final SearchNotifier _searchNotifier;
  final VaultRepository _vaultRepository;
  List<Credential> _credentials = [];
  List<Profile> _profiles = [];

  final List<dynamic> _results = [];
  List<dynamic> get results => _results;

  HomeViewModel(this._searchNotifier, this._vaultRepository) {
    _searchNotifier.addListener(_onSearchChanged);
    _fetch(_searchNotifier.query);
  }

  void _onSearchChanged() => _fetch(_searchNotifier.query);

  Future<void> _loadData() async {
    _profiles = await _vaultRepository.getAllProfiles();
    _credentials = await _vaultRepository.getAllCredentials();
  }

  Future<void> _fetch(String searchQuery) async {
    final String query = searchQuery.trim().toLowerCase();

    if (query.isEmpty && results.isEmpty) {
      await _loadData();
    }

    _results.clear();

    _results.addAll(
      _profiles.where((p) => p.name.toLowerCase().contains(query)),
    );

    _results.addAll(
      _credentials.where((c) => c.title.toLowerCase().contains(query)),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}
