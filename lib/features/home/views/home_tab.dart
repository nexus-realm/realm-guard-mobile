import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/security/vault_service.dart';
import '../../../shared/notifiers/fab_notifier.dart';
import '../../../shared/notifiers/fab_notifier_scope.dart';
import '../../../shared/notifiers/search_notifier_scope.dart';
import '../../../shared/viewmodels/home_view_model.dart';

class HomeTab extends StatefulWidget {
  final VaultService vaultService;

  const HomeTab({required this.vaultService, super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final VaultRepository _repository;
  HomeViewModel? _viewModel;
  // Référence mise en cache : on ne peut pas faire de lookup d'InheritedWidget
  // dans dispose() (le contexte y est désactivé).
  FabNotifier? _fabNotifier;

  @override
  void initState() {
    super.initState();
    _repository = VaultRepository(widget.vaultService.db);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fabNotifier?.register(
        icon: Icons.add,
        onPressed: () => _viewModel?.openAddBottomSheet(context),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fabNotifier = FabNotifierScope.of(context);
    _viewModel ??= HomeViewModel(SearchNotifierScope.of(context), _repository);
  }

  @override
  void dispose() {
    _fabNotifier?.unregister();
    _viewModel!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel!,
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    // 1) Chargement initial : on n'affiche pas l'état "vide" prématurément.
    if (_viewModel!.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = _viewModel!.results;

    // 2) Aucun élément : on distingue recherche sans résultat et coffre vide.
    if (results.isEmpty) {
      return _viewModel!.hasSearchQuery
          ? const _EmptyState(
              icon: Icons.search_off,
              title: 'Aucun résultat',
              message: 'Aucun élément ne correspond à votre recherche.',
            )
          : const _EmptyState(
              icon: Icons.lock_outline,
              title: 'Votre coffre est vide',
              message: 'Appuyez sur + pour ajouter un profil ou un identifiant.',
            );
    }

    // 3) Liste des éléments.
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        if (item is Profile) {
          return ListTile(
            title: Text(item.name),
            subtitle: const Text('Profil'),
            onTap: () {
              // TODO: View profile details
            },
          );
        } else if (item is CredentialWithProfile) {
          return ListTile(
            title: Text(item.credential.title),
            subtitle: Text(item.profile?.name ?? 'Sans profil'),
            onTap: () {
              // TODO: View credential details
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}

/// État vide générique (coffre vide ou recherche sans résultat).
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: textTheme.bodyMedium?.color),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
