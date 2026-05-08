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

  PersistentBottomSheetController? _controller;
  bool get isBottomSheetOpen => _controller != null;

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
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}
