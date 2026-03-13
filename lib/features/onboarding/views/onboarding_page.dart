import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding_step.dart';
import '../service/onboarding_storage_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/security/vault_service.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStep = _viewModel.currentStep;

    if (currentStep == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgress(currentStep),
              const SizedBox(height: 24),
              Expanded(
                child: _buildStepContent(currentStep),
              ),
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(OnboardingStep currentStep) {
    final currentIndex = OnboardingStep.values.indexOf(currentStep) + 1;
    return Text(
      'Etape $currentIndex/${OnboardingStep.values.length}',
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bienvenue dans Realm Guard',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Votre coffre-fort local chiffre vos donnees sensibles.\nCommencons la configuration en 3 etapes.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Definissez votre mot de passe maitre',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ce mot de passe sert a deriver la cle de chiffrement de votre coffre.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            enabled: !_viewModel.isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Mot de passe maitre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordConfirmationController,
            obscureText: true,
            enabled: !_viewModel.isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Confirmation du mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _viewModel.isSubmitting ? null : _submitMasterPassword,
            child: _viewModel.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Valider le mot de passe'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricChoiceStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Activer la biometrie ?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Vous pourrez deverrouiller rapidement votre coffre-fort avec votre empreinte ou Face ID si disponible.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _viewModel.isSubmitting
              ? null
              : () => _viewModel.completeBiometricStep(true),
          icon: const Icon(Icons.fingerprint),
          label: const Text('Oui, activer la biometrie'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _viewModel.isSubmitting
              ? null
              : () => _viewModel.completeBiometricStep(false),
          child: const Text('Non, utiliser uniquement le mot de passe'),
        ),
      ],
    );
  }
}

