import 'package:flutter/material.dart';

import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/view_title.dart';
import '../service/auth_service.dart';
import '../viewmodels/sync_view_model.dart';

/// Écran **Réglages → Synchronisation** (opt-in). Permet de créer un compte ou de
/// se connecter (OPAQUE zero-knowledge). L'app reste pleinement utilisable
/// hors-ligne sans compte.
class SyncPage extends StatefulWidget {
  const SyncPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final SyncViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SyncViewModel(authService: widget.authService);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _viewModel.submit(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _viewModel.isLoggedIn
              ? _buildConnected(context)
              : _buildForm(context),
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
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _viewModel.isLoading ? null : _viewModel.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isRegister = _viewModel.mode == AuthMode.register;
    final busy = _viewModel.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ViewTitle(title: 'Synchroniser', topTitle: 'Chiffré de bout en bout'),
            const SizedBox(height: 12),
            const Text(
              'Le serveur ne voit jamais votre mot de passe maître. Le coffre '
              'reste déchiffrable hors-ligne.',
            ),
            const SizedBox(height: 24),
            SegmentedButton<AuthMode>(
              segments: const [
                ButtonSegment(
                  value: AuthMode.login,
                  label: Text('Se connecter'),
                  icon: Icon(Icons.login),
                ),
                ButtonSegment(
                  value: AuthMode.register,
                  label: Text('Créer un compte'),
                  icon: Icon(Icons.person_add_alt),
                ),
              ],
              selected: {_viewModel.mode},
              onSelectionChanged: busy
                  ? null
                  : (selection) => _viewModel.setMode(selection.first),
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
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe maître',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Champ requis' : null,
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
          ],
        ),
      ),
    );
  }
}
