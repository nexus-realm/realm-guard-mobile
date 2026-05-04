import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
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
  String _passwordValue = '';
  String _passwordConfirmationValue = '';

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
    return !_viewModel.isSubmitting &&
        _isPasswordValid(_passwordValue) &&
        _passwordConfirmationValue.trim().isNotEmpty &&
        _passwordValue.trim() == _passwordConfirmationValue.trim();
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
      _passwordValue,
      _passwordConfirmationValue,
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
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: _buildProgress(currentStep),
      ),
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
    return Text(
      '$currentIndex/${_viewModel.totalStepCount}',
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: TextAlign.center,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Column(
          children: [
            ViewTitle(
              topTitle: 'Présentation',
              title: 'Bienvenue sur Realm Guard_',
            ),
            SizedBox(height: 16),
            Text(
              'Un coffre-fort offline first pour chiffré vos données sensibles. '
              'Nous allons affiner votre expérience dans les prochaines étapes.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Vous pourrez toujours modifier vos choix plus tard dans les paramètres.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _viewModel.isSubmitting
              ? null
              : _viewModel.completeWelcomeStep,
          child: const Text('Commencer'),
        ),
      ],
    );
  }

  Widget _buildMasterPasswordStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const Column(
          children: [
            ViewTitle(topTitle: 'Sécurisation', title: 'Mot de passe_'),
            SizedBox(height: 16),
            Text(
              'Ce mot de passe sert a générer la clé de chiffrement de votre coffre.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        PasswordForm(
          formKey: _formKey,
          newPassword: true,
          autoValidateMode: _autoValidateMode,
          enabled: !_viewModel.isSubmitting,
          onPasswordChanged: (value) {
            setState(() => _passwordValue = value);
          },
          onConfirmPasswordChanged: (value) {
            setState(() => _passwordConfirmationValue = value);
          },
        ),
        ElevatedButton(
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const ViewTitle(topTitle: 'Sécurisation', title: 'Biométrie_'),
        Column(
          spacing: 12,
          children: [
            Text(
              'Voulez-vous utiliser la biométrie pour dévérrouiller rapidement votre coffre-fort ?',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              'Vous aurez toujours la possibilité d\'utiliser votre mot de passe maitre pour vous authentifier.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              'Le mot de passe vous sera demandé de temps en temps pour renforcer la sécurité.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () => _viewModel.completeBiometricStep(true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Oui, activer la biometrie'),
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
