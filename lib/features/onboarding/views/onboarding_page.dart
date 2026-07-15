import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feature_flags/feature_flags_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
import '../../auth/service/auth_service.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/password_form.dart';
import '../../../shared/widgets/view_title.dart';
import '../data/onboarding_step.dart';
import '../data/password_validation_rule.dart';
import '../data/password_validation_rules.dart';
import '../service/onboarding_storage_service.dart';
import '../viewmodels/onboarding_view_model.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingStorageService onboardingStorageService;
  final VaultService vaultService;
  final FeatureFlagsController featureFlagsController;
  final AuthService authService;

  const OnboardingPage({
    required this.onboardingStorageService,
    required this.vaultService,
    required this.featureFlagsController,
    required this.authService,
    super.key,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingViewModel _viewModel;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  // Étape optionnelle de synchronisation : création de compte (OPAQUE).
  final TextEditingController _syncUsernameController = TextEditingController();
  final TextEditingController _syncPasswordController = TextEditingController();
  final _syncFormKey = GlobalKey<FormState>();
  _SyncStage _syncStage = _SyncStage.choice;

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      onboardingStorageService: widget.onboardingStorageService,
      vaultService: widget.vaultService,
      featureFlagsController: widget.featureFlagsController,
      authService: widget.authService,
    );
    _viewModel.addListener(_onViewModelUpdated);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _syncUsernameController.dispose();
    _syncPasswordController.dispose();
    super.dispose();
  }

  List<PasswordValidationRule> _passwordRules(String password) {
    return PasswordValidationRules.getPasswordValidationRules(password);
  }

  bool _isPasswordValid(String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return false;
    final rules = _passwordRules(trimmed);
    return rules.every((rule) => rule.validate(trimmed));
  }

  bool get _canSubmitMasterPassword {
    final String passwordValue = _passwordController.text;
    final String passwordConfirmationValue =
        _passwordConfirmationController.text;

    return !_viewModel.isSubmitting &&
        _isPasswordValid(passwordValue) &&
        passwordConfirmationValue.trim().isNotEmpty &&
        passwordValue.trim() == passwordConfirmationValue.trim();
  }

  void _onViewModelUpdated() {
    if (!mounted) {
      return;
    }

    if (_viewModel.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
    }

    setState(() {});
  }

  Future<void> _submitMasterPassword() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final success = await _viewModel.completeMasterPasswordStep(
      _passwordController.text,
      _passwordConfirmationController.text,
    );

    if (!success) {
      final errorMessage = _viewModel.errorMessage;

      if (mounted && errorMessage != null && errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStep = _viewModel.currentStep;

    if (currentStep == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slideAnimation = Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slideAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<OnboardingStep>(currentStep),
                          child: _buildStepContent(currentStep),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return _buildWelcomeStep();
      case OnboardingStep.masterPassword:
        return _buildMasterPasswordStep();
      case OnboardingStep.biometricChoice:
        return _buildBiometricChoiceStep();
      case OnboardingStep.totpChoice:
        return _buildTotpChoiceStep();
      case OnboardingStep.syncChoice:
        return _buildSyncChoiceStep();
    }
  }

  Widget _buildWelcomeStep() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            const ViewTitle(
              topTitle: 'Présentation',
              title: 'Bienvenue sur Realm Guard_',
            ),
            const SizedBox(height: 16),
            Text(
              'Un coffre-fort offline-first pour chiffrer vos données sensibles. '
              'Nous allons affiner votre expérience dans les prochaines étapes.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Vous pourrez toujours modifier vos choix plus tard dans les paramètres.',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
        GradientElevatedButton(
          onPressed: _viewModel.isSubmitting
              ? null
              : _viewModel.completeWelcomeStep,
          child: const Text('Commencer'),
        ),
      ],
    );
  }

  Widget _buildMasterPasswordStep() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          children: [
            const ViewTitle(topTitle: 'Sécurité', title: 'Mot de passe_'),
            const SizedBox(height: 16),
            Text(
              'Ce mot de passe sert à générer la clé de chiffrement de votre coffre.',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
        PasswordForm(
          formKey: _formKey,
          passwordController: _passwordController,
          passwordConfirmationController: _passwordConfirmationController,
          autoValidateMode: _autoValidateMode,
          enabled: !_viewModel.isSubmitting,
          onPasswordChanged: (_) => setState(() {}),
          onConfirmPasswordChanged: (_) => setState(() {}),
        ),
        GradientElevatedButton(
          onPressed: _canSubmitMasterPassword ? _submitMasterPassword : null,
          child: _viewModel.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider le mot de passe'),
        ),
      ],
    );
  }

  Widget _buildBiometricChoiceStep() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          spacing: 24,
          children: [
            const ViewTitle(topTitle: 'Sécurité', title: 'Biométrie_'),
            Column(
              spacing: 12,
              children: [
                Text(
                  'Voulez-vous utiliser la biométrie pour déverrouiller rapidement votre coffre-fort ?',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  'Vous aurez toujours la possibilité d\'utiliser votre mot de passe maître pour vous authentifier.',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  'Le mot de passe vous sera demandé de temps en temps pour renforcer la sécurité.',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientElevatedButton.icon(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => _viewModel.completeBiometricStep(true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Oui, activer la biométrie'),
            ),
            OutlinedButton(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => _viewModel.completeBiometricStep(false),
              child: const Text('Non, utiliser uniquement le mot de passe'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotpChoiceStep() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          spacing: 24,
          children: [
            const ViewTitle(topTitle: 'Personnalisation', title: 'TOTP_'),
            Column(
              spacing: 12,
              children: [
                Text(
                  'Realm Guard peut aussi générer vos codes à usage unique '
                  '(TOTP / 2FA), en plus de vos identifiants.',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  'Activez cette gestion si vous utilisez l\'authentification à '
                  'deux facteurs ; sinon, gardez une interface simplifiée.',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  'Vous pourrez changer ce choix à tout moment dans les '
                  'paramètres.',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientElevatedButton.icon(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => _viewModel.completeTotpChoiceStep(true),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Oui, activer la gestion des TOTP'),
            ),
            OutlinedButton(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => _viewModel.completeTotpChoiceStep(false),
              child: const Text('Non, interface simplifiée'),
            ),
          ],
        ),
      ],
    );
  }

  /// Étape **synchronisation** (optionnelle, dernière étape). Trois sous-états :
  /// choix hors-ligne/connecté → création de compte → confirmation de réussite.
  Widget _buildSyncChoiceStep() {
    switch (_syncStage) {
      case _SyncStage.choice:
        return _buildSyncChoice();
      case _SyncStage.register:
        return _buildSyncRegister();
      case _SyncStage.success:
        return _buildSyncSuccess();
    }
  }

  Widget _buildSyncChoice() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          spacing: 24,
          children: [
            const ViewTitle(
              topTitle: 'Multi-appareils',
              title: 'Synchronisation_',
            ),
            Column(
              spacing: 12,
              children: [
                Text(
                  'Realm Guard fonctionne parfaitement hors-ligne. Créez un '
                  'compte chiffré pour synchroniser, ou liez cet appareil à un '
                  'compte existant.',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  'Le mot de passe du compte est distinct du mot de passe maître '
                  'que vous définirez ensuite ; le serveur ne le voit jamais.',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientElevatedButton.icon(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => setState(() => _syncStage = _SyncStage.register),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Créer un compte'),
            ),
            OutlinedButton.icon(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => context.push(AppRoutes.pairedSetup),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('J\'ai déjà un compte — lier cet appareil'),
            ),
            TextButton(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : _viewModel.completeSyncStep,
              child: const Text('Continuer hors-ligne'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncRegister() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          spacing: 16,
          children: [
            const ViewTitle(
              topTitle: 'Synchronisation',
              title: 'Créer un compte_',
            ),
            Text(
              'Choisissez un nom d\'utilisateur et un mot de passe de compte '
              '(distinct du mot de passe maître, jamais transmis en clair).',
              style: textTheme.bodyLarge,
            ),
            Form(
              key: _syncFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  TextFormField(
                    controller: _syncUsernameController,
                    enabled: !_viewModel.isSubmitting,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Champ requis'
                        : null,
                  ),
                  TextFormField(
                    controller: _syncPasswordController,
                    enabled: !_viewModel.isSubmitting,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe du compte',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().length < 12)
                        ? 'Au moins 12 caractères'
                        : null,
                    onFieldSubmitted: (_) => _submitSyncAccount(),
                  ),
                  if (_viewModel.errorMessage != null)
                    Text(
                      _viewModel.errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                ],
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            GradientElevatedButton(
              onPressed: _viewModel.isSubmitting ? null : _submitSyncAccount,
              child: _viewModel.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer le compte'),
            ),
            TextButton(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => setState(() => _syncStage = _SyncStage.choice),
              child: const Text('Retour'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncSuccess() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Column(
          spacing: 16,
          children: [
            const ViewTitle(
              topTitle: 'Synchronisation',
              title: 'Compte créé_',
            ),
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Compte de synchronisation créé et session ouverte sur cet '
                    'appareil.',
                  ),
                ),
              ],
            ),
            Text(
              'Vous pourrez ajouter d\'autres appareils depuis les paramètres.',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
        GradientElevatedButton(
          onPressed: _viewModel.isSubmitting
              ? null
              : _viewModel.completeSyncStep,
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Future<void> _submitSyncAccount() async {
    final isValid = _syncFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final created = await _viewModel.registerSyncAccount(
      username: _syncUsernameController.text,
      password: _syncPasswordController.text,
    );
    if (!mounted || !created) return;
    setState(() => _syncStage = _SyncStage.success);
  }
}

/// Sous-étapes locales de l'écran de synchronisation d'onboarding.
enum _SyncStage { choice, register, success }
