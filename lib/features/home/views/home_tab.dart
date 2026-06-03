import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/notifiers/fab_notifier.dart';
import '../../../shared/notifiers/fab_notifier_scope.dart';
import '../../../shared/notifiers/search_notifier_scope.dart';
import '../../../shared/viewmodels/home_view_model.dart';

/// Onglet principal de la Vault : la liste des identifiants.
///
/// Les profils sont gérés dans un écran dédié (icône 👥 de l'AppBar) car ce
/// sont des données de référence, peu consultées au quotidien. Une TabBar par
/// type de secret (Identifiants / TOTP / Clés …) sera réintroduite ici lorsque
/// plusieurs types existeront.
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
        label: 'Identifiant',
        onPressed: () => _viewModel?.addCredential(context),
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
    if (_viewModel!.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final credentials = _viewModel!.filteredCredentials;
    if (credentials.isEmpty) {
      final hasQuery = _viewModel!.hasSearchQuery;
      return _EmptyState(
        icon: hasQuery ? Icons.search_off : Icons.vpn_key_outlined,
        title: hasQuery ? 'Aucun résultat' : 'Votre coffre est vide',
        message: hasQuery
            ? 'Aucun identifiant ne correspond à votre recherche.'
            : 'Appuyez sur + pour ajouter un identifiant.',
      );
    }

    return ListView.builder(
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final item = credentials[index];
        return ListTile(
          leading: const Icon(Icons.vpn_key),
          title: Text(item.credential.title),
          subtitle: Text(item.profile?.name ?? 'Sans profil'),
          onTap: () => context.push(
            '${AppRoutes.credentialDetail}/${item.credential.id}',
          ),
        );
      },
    );
  }
}

/// État vide générique (liste vide ou recherche sans résultat).
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
            Icon(icon, size: 48, color: AppColors.secondaryText),
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
