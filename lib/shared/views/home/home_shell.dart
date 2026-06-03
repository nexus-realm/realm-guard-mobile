import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifiers/fab_notifier.dart';
import '../../notifiers/fab_notifier_scope.dart';
import '../../notifiers/search_notifier.dart';
import '../../notifiers/search_notifier_scope.dart';

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
        tooltip: 'Profils',
        onPressed: () => context.push(AppRoutes.profiles),
        icon: const Icon(Icons.people_outline),
      ),
      IconButton(
        tooltip: 'Paramètres',
        onPressed: () => context.push(AppRoutes.settings),
        icon: const Icon(Icons.settings),
      ),
    ],
    const <Widget>[], // Onglet "Partage" (non implémenté) : aucune action.
  ];

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      context.go(tabs[index]);
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    _fabNotifier.dispose();
    _searchNotifier.dispose();
    _searchController.dispose();
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
          // IndexedStack garde `widget.child` (le child du ShellRoute GoRouter)
          // TOUJOURS monté : on évite ainsi de le retirer/réinsérer dans l'arbre
          // (ce qui cassait GoRouter : PopScope / GlobalKey dupliquée). L'onglet
          // "Partage" n'étant pas implémenté, on montre un placeholder.
          body: IndexedStack(
            index: _currentIndex,
            children: [widget.child, const _ComingSoonView()],
          ),
          floatingActionButton: ListenableBuilder(
            listenable: _fabNotifier,
            builder: (context, _) {
              // FAB réservé à l'onglet Vault (HomeTab reste monté sous l'onglet
              // Partage à cause de l'IndexedStack).
              if (_currentIndex != 0 || !_fabNotifier.visible) {
                return const SizedBox.shrink();
              }

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
              BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Partage'),
            ],
          ),
        ),
      ),
    );
  }
}
