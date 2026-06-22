import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../core/feature_flags/feature_flag.dart';
import '../../../core/feature_flags/feature_flags_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/notifiers/fab_notifier.dart';
import '../../../shared/notifiers/fab_notifier_scope.dart';
import '../../../shared/notifiers/search_notifier_scope.dart';
import '../../../shared/viewmodels/home_view_model.dart';
import 'widgets/credential_avatar.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/totp_list_tile.dart';
import 'widgets/vault_list_tile.dart';

/// Onglet principal de la Vault : une TabBar par type de secret
/// (Identifiants / TOTP). La recherche (AppBar de HomeShell) et le FAB sont
/// communs et contextualisés selon l'onglet actif.
///
/// Les profils restent gérés dans un écran dédié (icône 👥 de l'AppBar).
class HomeTab extends StatefulWidget {
  final VaultService vaultService;
  final FeatureFlagsController featureFlagsController;

  const HomeTab({
    required this.vaultService,
    required this.featureFlagsController,
    super.key,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late final VaultRepository _repository;
  late final TabController _tabController;
  HomeViewModel? _viewModel;
  // Référence mise en cache : lookup d'InheritedWidget interdit dans dispose().
  FabNotifier? _fabNotifier;

  @override
  void initState() {
    super.initState();
    _repository = VaultRepository(widget.vaultService.db);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    widget.featureFlagsController.addListener(_onFlagsChanged);

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
    widget.featureFlagsController.removeListener(_onFlagsChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fabNotifier?.unregister();
    _viewModel!.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _registerFab();
  }

  /// La gestion des TOTP a été (dés)activée dans les paramètres : recompose
  /// l'onglet (TabBar ou non) et réajuste le FAB contextuel.
  void _onFlagsChanged() {
    if (!mounted) return;
    setState(() {});
    _registerFab();
  }

  /// FAB contextuel : ajoute un identifiant ou un TOTP selon l'onglet actif.
  /// Si la gestion des TOTP est désactivée, il n'y a qu'un seul type d'ajout.
  void _registerFab() {
    final totpEnabled = widget.featureFlagsController.isEnabled(
      FeatureFlag.totp,
    );
    final isCredentials = !totpEnabled || _tabController.index == 0;
    _fabNotifier?.register(
      icon: Icons.add,
      label: isCredentials ? 'Identifiant' : 'TOTP',
      onPressed: () => isCredentials
          ? _viewModel?.addCredential(context)
          : _viewModel?.addTotp(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totpEnabled = widget.featureFlagsController.isEnabled(
      FeatureFlag.totp,
    );

    // TOTP désactivé : interface simplifiée, uniquement la liste d'identifiants
    // (ni TabBar, ni onglet/FAB TOTP).
    if (!totpEnabled) {
      return ListenableBuilder(
        listenable: _viewModel!,
        builder: (context, _) {
          if (_viewModel!.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCredentialsTab();
        },
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.mainColor,
          indicatorWeight: 3,
          labelColor: AppColors.mainColor,
          unselectedLabelColor: AppColors.secondaryText,
          dividerColor: AppColors.secondaryBackground,
          tabs: const [
            Tab(text: 'Identifiants'),
            Tab(text: 'TOTP'),
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
                children: [_buildCredentialsTab(), _buildTotpsTab()],
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
        emptyIcon: Icons.vpn_key_outlined,
        emptyTitle: 'Aucun identifiant',
        emptyMessage: 'Appuyez sur + pour ajouter un identifiant.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final item = credentials[index];
        final profile = item.profile;
        return VaultListTile(
          leading: CredentialAvatar(
            title: item.credential.title,
            uri: item.credential.uri,
            radius: 18,
          ),
          title: item.credential.title,
          subtitle: profile?.name ?? 'Sans profil',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.credential.favorite)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppDecorations.accentGlow,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
              if (profile != null)
                ProfileAvatar(
                  name: profile.name,
                  colorValue: profile.color,
                  radius: 12,
                ),
            ],
          ),
          onTap: () => context.push(
            '${AppRoutes.credentialDetail}/${item.credential.id}',
          ),
        );
      },
    );
  }

  Widget _buildTotpsTab() {
    final totps = _viewModel!.filteredTotps;
    if (totps.isEmpty) {
      return _emptyState(
        emptyIcon: Icons.timer_outlined,
        emptyTitle: 'Aucun code TOTP',
        emptyMessage: 'Appuyez sur + pour ajouter un code à validation en '
            'deux étapes.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: totps.length,
      itemBuilder: (context, index) {
        final item = totps[index];
        return TotpListTile(
          totp: item.totp,
          subtitle: item.totp.account ?? item.profile?.name ?? '',
          onTap: () => context.push('${AppRoutes.totpDetail}/${item.totp.id}'),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    final hasQuery = _viewModel!.hasSearchQuery;
    return _EmptyState(
      icon: hasQuery ? Icons.search_off : emptyIcon,
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
