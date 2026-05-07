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
        label: 'Ajouter',
        onPressed: () => _viewModel?.onFabPressed(),
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
            : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  if (item is Profile) {
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('Profil'),
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
      },
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            //   FloatingActionButton(
            //     heroTag: 'add_profile',
            //     onPressed: _addProfile,
            //     child: const Icon(Icons.person_add),
            //   ),
            //   const SizedBox(height: 16),
            //   FloatingActionButton(
            //     heroTag: 'add_credential',
            //     onPressed: _addCredential,
            //     child: const Icon(Icons.add),
            //   ),
          ],
        ),
      ),
    );
  }

  // void _addProfile() {
  //   // TODO: Show dialog to add profile
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Ajouter un profil'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             decoration: const InputDecoration(labelText: 'Nom du profil'),
  //             onSubmitted: (name) async {
  //               if (name.isNotEmpty) {
  //                 await _repository.addProfile(name, []);
  //                 await _loadData();
  //                 if (context.mounted) {
  //                   Navigator.of(context).pop();
  //                 }
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // void _addCredential() {
  //   // TODO: Show dialog to add credential
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Ajouter un identifiant'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             decoration: const InputDecoration(labelText: 'Titre'),
  //             onSubmitted: (title) async {
  //               if (title.isNotEmpty) {
  //                 await _repository.addCredential(
  //                   title,
  //                   'encrypted data placeholder',
  //                   null,
  //                 );
  //                 await _loadData();
  //                 if (context.mounted) {
  //                   Navigator.of(context).pop();
  //                 }
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
