import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
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

  const OnboardingPage({
    required this.onboardingStorageService,
    required this.vaultService,
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

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      onboardingStorageService: widget.onboardingStorageService,
      vaultService: widget.vaultService,
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
                    _buildProgress(currentStep),
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

  Widget _buildProgress(OnboardingStep currentStep) {
    if (currentStep == OnboardingStep.welcome) {
      return const SizedBox.shrink();
    }

    final currentIndex = _viewModel.currentStepIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '$currentIndex/${_viewModel.totalStepCount}',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
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
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
}
