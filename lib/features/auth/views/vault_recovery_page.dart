import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../../onboarding/service/onboarding_storage_service.dart';
import '../service/auth_service.dart';
import '../viewmodels/vault_recovery_view_model.dart';

/// Onboarding « **récupérer mon coffre** » : pour un compte dont on n'a plus aucun
/// appareil. Demande le mot de passe **du compte** (ouvre l'enveloppe serveur) puis
/// le mot de passe **maître** (désenrobe la VaultKey) — les deux sont nécessaires.
class VaultRecoveryPage extends StatefulWidget {
  const VaultRecoveryPage({
    required this.authService,
    required this.vaultService,
    required this.onboardingStorageService,
    super.key,
  });

  final AuthService authService;
  final VaultService vaultService;
  final OnboardingStorageService onboardingStorageService;

  @override
  State<VaultRecoveryPage> createState() => _VaultRecoveryPageState();
}

class _VaultRecoveryPageState extends State<VaultRecoveryPage> {
  late final VaultRecoveryViewModel _viewModel;
  final _usernameController = TextEditingController();
  final _accountPasswordController = TextEditingController();
  final _masterPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = VaultRecoveryViewModel(
      authService: widget.authService,
      recover: widget.vaultService.recoverVaultFromBackup,
      onboardingStorage: widget.onboardingStorageService,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _accountPasswordController.dispose();
    _masterPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    FocusScope.of(context).unfocus();
    await _viewModel.fetchBackup(
      username: _usernameController.text,
      password: _accountPasswordController.text,
    );
  }

  Future<void> _restore() async {
    FocusScope.of(context).unfocus();
    final restored = await _viewModel.restore(_masterPasswordController.text);
    if (!mounted || !restored) return;
    // Coffre restauré : on repasse par la **porte de démarrage** pour ré-évaluer
    // le progrès à neuf (l'onboarding reprend à la biométrie). Aller directement
    // sur `/onboarding` réutiliserait la page périmée restée sous ce `push`.
    context.go(AppRoutes.startup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récupérer mon coffre')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _viewModel.backupFetched
                ? _masterPasswordStep(context)
                : _accountStep(context),
          ),
        ),
      ),
    );
  }

  Widget _accountStep(BuildContext context) {
    final busy = _viewModel.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ViewTitle(topTitle: 'Récupération', title: 'Votre compte_'),
        const SizedBox(height: 16),
        const Text(
          'Connectez-vous pour récupérer la clé de votre coffre sauvegardée sur '
          'le serveur. Elle y est scellée : le serveur ne peut pas la lire.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _usernameController,
          enabled: !busy,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: "Nom d'utilisateur",
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountPasswordController,
          enabled: !busy,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe du compte',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _fetch(),
        ),
        _errorText(context),
        const SizedBox(height: 24),
        GradientElevatedButton(
          onPressed: busy ? null : _fetch,
          child: busy ? const _Spinner() : const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _masterPasswordStep(BuildContext context) {
    final busy = _viewModel.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ViewTitle(
          topTitle: 'Récupération',
          title: 'Mot de passe maître_',
        ),
        const SizedBox(height: 16),
        const Text(
          'Clé sauvegardée récupérée. Saisissez votre mot de passe maître pour la '
          'déchiffrer et restaurer le coffre sur cet appareil.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _masterPasswordController,
          enabled: !busy,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe maître',
            prefixIcon: Icon(Icons.key_outlined),
          ),
          onSubmitted: (_) => _restore(),
        ),
        _errorText(context),
        const SizedBox(height: 24),
        GradientElevatedButton(
          onPressed: busy ? null : _restore,
          child: busy ? const _Spinner() : const Text('Restaurer le coffre'),
        ),
      ],
    );
  }

  Widget _errorText(BuildContext context) {
    final error = _viewModel.error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        error,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
