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

class HomeTab extends StatefulWidget {
  final VaultService vaultService;

  const HomeTab({required this.vaultService, super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late final VaultRepository _repository;
  late final TabController _tabController;
  HomeViewModel? _viewModel;
  // Référence mise en cache : on ne peut pas faire de lookup d'InheritedWidget
  // dans dispose() (le contexte y est désactivé).
  FabNotifier? _fabNotifier;

  @override
  void initState() {
    super.initState();
    _repository = VaultRepository(widget.vaultService.db);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerFab();
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fabNotifier?.unregister();
    _viewModel!.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // indexIsChanging filtre les évènements intermédiaires de l'animation.
    if (!_tabController.indexIsChanging) _registerFab();
  }

  /// Le FAB est contextuel : il ajoute un identifiant ou un profil selon
  /// l'onglet actif.
  void _registerFab() {
    final isCredentials = _tabController.index == 0;
    _fabNotifier?.register(
      icon: Icons.add,
      label: isCredentials ? 'Identifiant' : 'Profil',
      onPressed: () => isCredentials
          ? _viewModel?.addCredential(context)
          : _viewModel?.addProfile(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Identifiants'),
            Tab(text: 'Profils'),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel!,
            builder: (context, _) {
              if (_viewModel!.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                controller: _tabController,
                children: [_buildCredentialsTab(), _buildProfilesTab()],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsTab() {
    final credentials = _viewModel!.filteredCredentials;
    if (credentials.isEmpty) {
      return _emptyState(
        searchIcon: Icons.search_off,
        emptyIcon: Icons.vpn_key_outlined,
        emptyTitle: 'Aucun identifiant',
        emptyMessage: 'Appuyez sur + pour ajouter un identifiant.',
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

  Widget _buildProfilesTab() {
    final profiles = _viewModel!.filteredProfiles;
    if (profiles.isEmpty) {
      return _emptyState(
        searchIcon: Icons.search_off,
        emptyIcon: Icons.person_outline,
        emptyTitle: 'Aucun profil',
        emptyMessage: 'Appuyez sur + pour ajouter un profil.',
      );
    }
    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(profile.name),
          onTap: () => context.push('${AppRoutes.profileDetail}/${profile.id}'),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData searchIcon,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    final hasQuery = _viewModel!.hasSearchQuery;
    return _EmptyState(
      icon: hasQuery ? searchIcon : emptyIcon,
      title: hasQuery ? 'Aucun résultat' : emptyTitle,
      message: hasQuery
          ? 'Aucun élément ne correspond à votre recherche.'
          : emptyMessage,
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
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
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
