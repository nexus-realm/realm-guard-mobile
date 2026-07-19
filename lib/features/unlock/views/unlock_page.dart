import 'package:flutter/material.dart';

import '../../../shared/widgets/app_snackbar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/app_lock_controller.dart';
import '../../../core/security/unlock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/password_form.dart';
import '../../../shared/widgets/view_title.dart';
import '../viewmodels/unlock_view_model.dart';

class UnlockPage extends StatefulWidget {
  final UnlockService unlockService;
  final AppLockController lockController;

  const UnlockPage({
    required this.unlockService,
    required this.lockController,
    super.key,
  });

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> with WidgetsBindingObserver {
  late final UnlockViewModel _viewModel;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = UnlockViewModel(unlockService: widget.unlockService);
    _viewModel.addListener(_onViewModelUpdated);
    _viewModel.initialize();

    // Cas "inactivité" : on atterrit ici alors que l'app est déjà au premier
    // plan, donc on affiche le message dès le premier frame. Le cas
    // "arrière-plan" est géré par didChangeAppLifecycleState (affichage au
    // retour au premier plan, sinon la snackbar s'écoulerait pendant que l'app
    // est masquée).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _showLockMessageIfAny();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Le verrouillage automatique en arrière-plan survient pendant que l'app
    // est masquée : on informe l'utilisateur à son retour au premier plan.
    if (state == AppLifecycleState.resumed) {
      _showLockMessageIfAny();
    }
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
      AppSnackbar.error(context, _viewModel.errorMessage!);
    }
  }

  /// Affiche une snackbar décrivant la raison du dernier verrouillage
  /// automatique, s'il y en a un en attente (consommé une seule fois).
  void _showLockMessageIfAny() {
    final reason = widget.lockController.takePendingMessage();
    if (reason == null || !mounted) return;

    final message = switch (reason) {
      LockReason.background =>
        'Coffre verrouillé : l\'application est passée en arrière-plan.',
      LockReason.inactivity =>
        'Coffre verrouillé après une période d\'inactivité.',
    };

    AppSnackbar.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
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
                          Text(
                            'Ouvrez votre coffre-fort pour accéder à vos '
                            'secrets. Utilisez votre empreinte digitale ou '
                            'entrez votre mot de passe maître.',
                            style: Theme.of(context).textTheme.bodyLarge,
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
                                    'Trop de tentatives. Réessayez dans ${_viewModel.remainingLockoutLabel}',
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
                            child: GradientElevatedButton.icon(
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
