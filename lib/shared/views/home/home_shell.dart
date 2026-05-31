import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifiers/fab_notifier.dart';
import '../../notifiers/fab_notifier_scope.dart';
import '../../notifiers/search_notifier.dart';
import '../../notifiers/search_notifier_scope.dart';

enum CategoryFilter { all, profiles, credentials }

/// Placeholder affiché pour l'onglet "Partage" tant que la fonctionnalité
/// n'est pas implémentée.
class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.share_outlined,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'Le partage arrive bientôt',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final SearchNotifier _searchNotifier = SearchNotifier();
  final FabNotifier _fabNotifier = FabNotifier();
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  final List<String> tabs = [AppRoutes.home, AppRoutes.home];

  // Une entrée d'actions par onglet (même longueur que la barre de navigation).
  late final List<List<Widget>> actions = [
    [
      IconButton(
        tooltip: 'Paramètres',
        onPressed: _openSettings,
        icon: const Icon(Icons.settings),
      ),
    ],
    const <Widget>[], // Onglet "Partage" (non implémenté) : aucune action.
  ];

  bool get _isDeveloperCategoryEnabled {
    return kDebugMode ||
        const bool.fromEnvironment(
          'ENABLE_DEVELOPER_SETTINGS',
          defaultValue: false,
        );
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      context.go(tabs[index]);
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(
                    'Paramètres',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  _buildSettingsCategory(
                    context: sheetContext,
                    title: 'Général',
                    children: const [
                      ListTile(
                        leading: Icon(Icons.language),
                        title: Text('Langue'),
                        subtitle: Text('Configuration à venir'),
                        enabled: false,
                      ),
                      ListTile(
                        leading: Icon(Icons.palette_outlined),
                        title: Text('Thème'),
                        subtitle: Text('Configuration à venir'),
                        enabled: false,
                      ),
                    ],
                  ),
                  _buildSettingsCategory(
                    context: sheetContext,
                    title: 'Sécurité',
                    children: const [
                      ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Mot de passe maître'),
                        subtitle: Text('Configuration à venir'),
                        enabled: false,
                      ),
                      ListTile(
                        leading: Icon(Icons.fingerprint),
                        title: Text('Biométrie'),
                        subtitle: Text('Configuration à venir'),
                        enabled: false,
                      ),
                    ],
                  ),
                  if (_isDeveloperCategoryEnabled)
                    _buildSettingsCategory(
                      context: sheetContext,
                      title: 'Developer',
                      children: [
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('Reset complet de l\'application'),
                          subtitle: const Text(
                            'Supprime les paramètres, l\'état onboarding et le coffre local.',
                          ),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _confirmAndResetAppState();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCategory({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndResetAppState() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset complet'),
          content: const Text(
            'Cette action va supprimer tous les paramètres locaux et les données du coffre. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    try {
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      final supportDirectory = await getApplicationSupportDirectory();
      final filesToDelete = [
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite'),
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite-shm'),
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite-wal'),
        p.join(supportDirectory.path, 'realmguard_security_metadata.salt'),
      ];

      for (final filePath in filesToDelete) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application réinitialisée.')),
      );
      context.go(AppRoutes.startup);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de réinitialiser les données pour le moment.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fabNotifier.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchNotifierScope(
      notifier: _searchNotifier,
      child: FabNotifierScope(
        notifier: _fabNotifier,
        child: Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchNotifier.updateQuery,
            ),
            actionsPadding: const EdgeInsets.only(right: 8),
            // Accès borné : évite tout RangeError si un onglet n'a pas d'action.
            actions: _currentIndex < actions.length
                ? actions[_currentIndex]
                : const <Widget>[],
          ),
          // L'onglet "Partage" n'est pas encore implémenté : on affiche un
          // placeholder au lieu du contenu du coffre (les deux onglets pointent
          // vers /home).
          body: _currentIndex == 0 ? widget.child : const _ComingSoonView(),
          floatingActionButton: ListenableBuilder(
            listenable: _fabNotifier,
            builder: (context, _) {
              if (!_fabNotifier.visible) return const SizedBox.shrink();

              if (_fabNotifier.label == null) {
                return FloatingActionButton(
                  onPressed: _fabNotifier.call,
                  child: Icon(_fabNotifier.icon),
                );
              }

              return FloatingActionButton.extended(
                onPressed: _fabNotifier.call,
                icon: Icon(_fabNotifier.icon),
                label: Text(_fabNotifier.label!),
              );
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            backgroundColor: AppColors.secondaryBackground,
            selectedItemColor: AppColors.mainColor,
            unselectedItemColor: AppColors.secondaryText,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Vault'),
              BottomNavigationBarItem(
                icon: Icon(Icons.share),
                label: 'Partage',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
