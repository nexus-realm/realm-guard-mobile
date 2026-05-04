import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/unlock_service.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/unlock_view_model.dart';

class UnlockPage extends StatefulWidget {
  final UnlockService unlockService;

  const UnlockPage({required this.unlockService, super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  late final UnlockViewModel _viewModel;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = UnlockViewModel(unlockService: widget.unlockService);
    _viewModel.addListener(_onViewModelUpdated);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (!mounted) return;

    if (_viewModel.isUnlocked) {
      context.go(AppRoutes.home);
      return;
    }

    // Afficher messages d'erreur
    if (_viewModel.errorMessage != null &&
        _viewModel.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(elevation: 0),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 24,
                    children: [
                      const Column(
                        children: [
                          ViewTitle(
                            topTitle: 'Déverrouillage',
                            title: 'Ouvrez l\'application',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Ouvrez votre coffre-fort pour accéder à vos '
                            'secrets. Utilisez votre empreinte digitale ou '
                            'entrez votre mot de passe maître.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe maître',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        enabled: !_viewModel.isLoading,
                        onSubmitted:
                            _viewModel.isLoading ||
                                (_viewModel.remainingLockout != null &&
                                    _viewModel.remainingLockout!.inSeconds > 0)
                            ? null
                            : (value) {
                                _viewModel.attemptPassword(value);
                                _passwordController.clear();
                              },
                      ),
                      const SizedBox(height: 16),
                      if (_viewModel.remainingLockout != null &&
                          _viewModel.remainingLockout!.inSeconds > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trop de tentatives. Réessayez dans ${_viewModel.remainingLockout!.inSeconds}s',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed:
                            _viewModel.isLoading ||
                                (_viewModel.remainingLockout != null &&
                                    _viewModel.remainingLockout!.inSeconds > 0)
                            ? null
                            : () {
                                _viewModel.attemptPassword(
                                  _passwordController.text,
                                );
                                _passwordController.clear();
                              },
                        icon: _viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_open),
                        label: const Text('Déverrouiller'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
