import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/security/vault_service.dart';
import '../../../shared/notifiers/fab_notifier_scope.dart';
import '../../../shared/notifiers/search_notifier_scope.dart';
import '../../../shared/viewmodels/home_view_model.dart';

enum CategoryFilter { all, profiles, credentials }

class HomeTab extends StatefulWidget {
  final VaultService vaultService;

  const HomeTab({required this.vaultService, super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final VaultRepository _repository;
  HomeViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _repository = VaultRepository(widget.vaultService.db);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FabNotifierScope.of(context).register(
        icon: Icons.add,
        onPressed: () => _viewModel?.openAddBottomSheet(context),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= HomeViewModel(SearchNotifierScope.of(context), _repository);
  }

  @override
  void dispose() {
    FabNotifierScope.of(context).unregister();
    _viewModel!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel!,
      builder: (context, _) {
        final results = _viewModel!.results;
        return results.isEmpty
            ? const Center(child: Text('Aucun élément trouvé'))
            : Stack(
              children:[
                ListView.builder(
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
                ),
                if (_viewModel!.isBottomSheetOpen)
                  GestureDetector(
                    onTap: () => _viewModel?.closeBottomSheet(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
              ],
            );
      },
    );
  }
}
