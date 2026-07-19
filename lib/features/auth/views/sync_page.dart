import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/choice_card.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../data/account_credential_rules.dart';
import '../service/auth_service.dart';
import '../viewmodels/sync_view_model.dart';

/// Écran **Réglages → Synchronisation** (opt-in). Permet de créer un compte ou de
/// se connecter (OPAQUE zero-knowledge). L'app reste pleinement utilisable
/// hors-ligne sans compte.
class SyncPage extends StatefulWidget {
  const SyncPage({
    required this.authService,
    required this.backupVaultKey,
    super.key,
  });

  final AuthService authService;

  /// Sauvegarde la VaultKey enrobée avec la clé exportée du login (`false` si le
  /// coffre n'existe pas encore).
  final Future<bool> Function(Uint8List exportKey) backupVaultKey;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final SyncViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  /// `null` tant qu'aucune carte n'est choisie (on affiche les deux options) ;
  /// sinon on affiche le formulaire du mode retenu.
  AuthMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    _viewModel = SyncViewModel(
      authService: widget.authService,
      backupVaultKey: widget.backupVaultKey,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _chooseMode(AuthMode mode) {
    _viewModel.setMode(mode);
    setState(() => _selectedMode = mode);
  }

  void _backToChoice() {
    setState(() => _selectedMode = null);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _viewModel.submit(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _logout() async {
    await _viewModel.logout();
    if (mounted) setState(() => _selectedMode = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoggedIn) return _buildConnected(context);
            final mode = _selectedMode;
            return mode == null
                ? _buildModeChoice(context)
                : _buildCredentialsForm(context, mode);
          },
        ),
      ),
    );
  }

  Widget _buildConnected(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ViewTitle(title: 'Compte lié', topTitle: 'Synchronisation'),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Synchronisation active sur cet appareil.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _viewModel.vaultKeyBackedUp
                    ? Icons.backup_outlined
                    : Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _viewModel.vaultKeyBackedUp
                      ? 'Clé du coffre sauvegardée sur le serveur, scellée par votre '
                            'mot de passe de compte. Le serveur ne peut pas la lire.'
                      : "Clé du coffre non sauvegardée. Reconnectez-vous une fois le "
                            'coffre créé pour activer la sauvegarde.',
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _viewModel.isLoading ? null : _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  /// Choix du mode : deux cartes explicites (créer / se connecter), à la place
  /// d'un simple bouton segmenté — cohérent avec l'étape « en ligne » de
  /// l'onboarding.
  Widget _buildModeChoice(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ViewTitle(
            title: 'Synchroniser',
            topTitle: 'Chiffré de bout en bout',
          ),
          const SizedBox(height: 12),
          const Text(
            'Le mot de passe du compte est distinct de votre mot de passe '
            'maître. Le serveur ne le voit jamais (OPAQUE) et le coffre reste '
            'déchiffrable hors-ligne.',
          ),
          const SizedBox(height: 24),
          ChoiceCard(
            icon: Icons.person_add_alt,
            title: 'Créer un compte',
            subtitle: 'Nouveau compte, chiffré de bout en bout.',
            onTap: () => _chooseMode(AuthMode.register),
          ),
          const SizedBox(height: 12),
          ChoiceCard(
            icon: Icons.login,
            title: 'Se connecter',
            subtitle: "J'ai déjà un compte de synchronisation.",
            onTap: () => _chooseMode(AuthMode.login),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsForm(BuildContext context, AuthMode mode) {
    final isRegister = mode == AuthMode.register;
    final busy = _viewModel.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ViewTitle(
              title: isRegister ? 'Créer un compte' : 'Se connecter',
              topTitle: 'Synchronisation',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              enabled: !busy,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Nom d'utilisateur",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Champ requis';
                }
                return isRegister
                    ? AccountCredentialRules.validateUsername(value)
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe du compte',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Champ requis';
                return isRegister
                    ? AccountCredentialRules.validatePassword(value)
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_viewModel.error != null) ...[
              const SizedBox(height: 16),
              Text(
                _viewModel.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 28),
            GradientElevatedButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isRegister ? 'Créer le compte' : 'Se connecter'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : _backToChoice,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
