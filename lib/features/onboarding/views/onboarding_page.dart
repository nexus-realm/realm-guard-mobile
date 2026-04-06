import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/view_title.dart';
import '../data/onboarding_step.dart';
import '../data/password_validation_rule.dart';
import '../service/onboarding_storage_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/security/vault_service.dart';
import '../viewmodels/onboarding_view_model.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingStorageService onboardingStorageService;
  final VaultService vaultService;

  const OnboardingPage({required this.onboardingStorageService, required this.vaultService, super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingViewModel _viewModel;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isPasswordConfirmationObscured = true;

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
    return _viewModel.getPasswordValidationRules(password);
  }

  bool _isPasswordValid(String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return false;
    final rules = _passwordRules(trimmed);
    return rules.every((rule) => rule.validate(trimmed));
  }

  bool get _canSubmitMasterPassword {
    final password = _passwordController.text;
    final confirmation = _passwordConfirmationController.text;
    return !_viewModel.isSubmitting &&
        _isPasswordValid(password) &&
        confirmation.trim().isNotEmpty &&
        password.trim() == confirmation.trim();
  }

  String? _passwordValidator(String? value) {
    final password = (value ?? '').trim();

    if (password.isEmpty) {
      return 'Veuillez saisir un mot de passe.';
    }

    final rules = _passwordRules(password);
    final allValid = rules.every((rule) => rule.validate(password));

    if (!allValid) {
      return 'Le mot de passe ne respecte pas toutes les conditions.';
    }

    return null;
  }

  String? _passwordConfirmationValidator(String? value) {
    final confirmation = (value ?? '').trim();
    final password = _passwordController.text.trim();

    if (confirmation.isEmpty) {
      return 'Veuillez confirmer le mot de passe.';
    }

    if (confirmation != password) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
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
      return;
    }

    _passwordController.clear();
    _passwordConfirmationController.clear();
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
      appBar: AppBar(elevation: 0, centerTitle: true, title: _buildProgress(currentStep)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
      children: [
        const ViewTitle(topTitle: 'Présentation', title: 'Bienvenue sur Realm Guard_'),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Text(
              'Un coffre-fort offline first pour chiffré vos données sensibles.'
              'Nous allons affiner votre expérience entre lançant la configuration en 3 étapes.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              'Vous pourrez toujours modifier vos choix plus tard dans les paramètres.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            ElevatedButton(
              onPressed: _viewModel.isSubmitting ? null : _viewModel.completeWelcomeStep,
              child: const Text('Commencer'),
            ),
          ],
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
        Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            spacing: 12,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                enabled: !_viewModel.isSubmitting,
                validator: _passwordValidator,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Mot de passe maitre',
                  suffixIcon: IconButton(
                    tooltip: _isPasswordObscured
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _passwordConfirmationController,
                obscureText: _isPasswordConfirmationObscured,
                enabled: !_viewModel.isSubmitting,
                validator: _passwordConfirmationValidator,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Confirmation du mot de passe',
                  suffixIcon: IconButton(
                    tooltip: _isPasswordConfirmationObscured
                        ? 'Afficher la confirmation'
                        : 'Masquer la confirmation',
                    onPressed: () {
                      setState(() {
                        _isPasswordConfirmationObscured =
                            !_isPasswordConfirmationObscured;
                      });
                    },
                    icon: Icon(
                      _isPasswordConfirmationObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              _buildPasswordValidationRules(),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _canSubmitMasterPassword ? _submitMasterPassword : null,
          child: _viewModel.isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Valider le mot de passe'),
        ),
      ],
    );
  }

  Widget _buildPasswordValidationRules() {
    final password = _passwordController.text;
    final rules = _viewModel.getPasswordValidationRules(password);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rules.map((rule) {
            final isValid = rule.validate(password);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: isValid ? AppColors.success : AppColors.grey2,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rule.label,
                    style: TextStyle(fontSize: 14, color: isValid ? AppColors.success : AppColors.grey2),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
              onPressed: _viewModel.isSubmitting ? null : () => _viewModel.completeBiometricStep(true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Oui, activer la biometrie'),
            ),
            OutlinedButton(
              onPressed: _viewModel.isSubmitting ? null : () => _viewModel.completeBiometricStep(false),
              child: const Text('Non, utiliser uniquement le mot de passe'),
            ),
          ],
        ),
      ],
    );
  }
}
