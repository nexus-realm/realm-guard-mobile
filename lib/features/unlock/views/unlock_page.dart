import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/unlock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/password_form.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

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
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (!mounted) return;

    if (_viewModel.isUnlocked) {
      context.go(AppRoutes.home);
      return;
    }

    // Afficher messages d'erreur seulement pour les erreurs de mot de passe
    if (_viewModel.strategy == UnlockStrategy.password &&
        _viewModel.errorMessage != null &&
        _viewModel.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: AppColors.darkRed,
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
                    children: [
                      Column(
                        spacing: 16,
                        children: [
                          const ViewTitle(
                            topTitle: 'Déverrouillage',
                            title: 'Ouvrez l\'application',
                          ),
                          const Text(
                            'Ouvrez votre coffre-fort pour accéder à vos '
                            'secrets. Utilisez votre empreinte digitale ou '
                            'entrez votre mot de passe maître.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 16,
                            children: [
                              PasswordForm(
                                formKey: _formKey,
                                passwordController: _passwordController,
                                enabled: !_viewModel.isLoading,
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),
                              if (_viewModel.remainingLockout != null &&
                                  _viewModel.remainingLockout!.inSeconds > 0)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(color: AppColors.error),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Trop de tentatives. Réessayez dans ${_viewModel.remainingLockout!.inSeconds}s',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _viewModel.isLoading ||
                                      (_viewModel.remainingLockout != null &&
                                          _viewModel
                                                  .remainingLockout!
                                                  .inSeconds >
                                              0)
                                  ? null
                                  : () {
                                      _viewModel.attemptPassword(
                                        _passwordController.text,
                                      );
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
                          ),
                          if (_viewModel.strategy == UnlockStrategy.biometric)
                            IconButton(
                              onPressed: () {
                                _viewModel.attemptBiometric();
                              },
                              icon: const Icon(Icons.fingerprint),
                            ),
                        ],
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
