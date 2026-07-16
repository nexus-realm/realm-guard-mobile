import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/security/vault_service.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/password_form.dart';
import '../../onboarding/service/onboarding_storage_service.dart';
import '../service/pairing_service.dart';
import '../viewmodels/paired_setup_view_model.dart';
import 'pairing_qr_view.dart';
import 'pairing_result_views.dart';

/// Onboarding « **lier cet appareil** » : affiche un QR, reçoit la VaultKey depuis un
/// appareil déjà connecté, puis demande un **code local** et installe le coffre.
class PairedSetupPage extends StatefulWidget {
  const PairedSetupPage({
    required this.pairingService,
    required this.vaultService,
    required this.onboardingStorageService,
    super.key,
  });

  final PairingService pairingService;
  final VaultService vaultService;
  final OnboardingStorageService onboardingStorageService;

  @override
  State<PairedSetupPage> createState() => _PairedSetupPageState();
}

class _PairedSetupPageState extends State<PairedSetupPage> {
  late final PairedSetupViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = PairedSetupViewModel(
      pairing: widget.pairingService,
      install: (vaultKey, password) => widget.vaultService
          .installPairedVaultKey(vaultKey: vaultKey, localPassword: password),
      onboardingStorage: widget.onboardingStorageService,
    );
    _viewModel.startPairing();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final installed = await _viewModel.installVault(
      _passwordController.text,
      _confirmationController.text,
    );
    if (!mounted || !installed) return;
    // Coffre installé : l'onboarding reprend (biométrie, préférences).
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lier cet appareil')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    // Tour 2 fait : la VaultKey est arrivée → mot de passe local.
    if (_viewModel.vaultKeyReceived) return _localPasswordStep(context);

    final error = _viewModel.error;
    if (error != null) {
      return PairingStatusView(
        icon: Icons.error_outline,
        title: 'Pairing échoué',
        message: error,
      );
    }

    // Tour 1 fait : on affiche le SAS **avant** tout transfert, le temps que
    // l'utilisateur le compare et confirme sur l'appareil source.
    final sas = _viewModel.sas;
    if (sas != null) return _sasStep(context, sas);

    return _qrStep(context);
  }

  /// Comparaison du SAS : le coffre n'a pas encore été transmis, la source attend la
  /// confirmation de l'utilisateur.
  Widget _sasStep(BuildContext context, String sas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairingSasView(sas: sas),
        const SizedBox(height: 32),
        const Text(
          "Vérifiez que ce code est identique sur l'autre appareil, puis confirmez "
          'là-bas. Le coffre ne sera transmis qu'
          'après.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _qrStep(BuildContext context) {
    return PairingQrView(
      qrPayload: _viewModel.qrPayload,
      waiting: _viewModel.waiting,
    );
  }

  Widget _localPasswordStep(BuildContext context) {
    final busy = _viewModel.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairingSasView(sas: _viewModel.sas!),
        const SizedBox(height: 32),
        const Text(
          'Définissez un code de déverrouillage pour CET appareil. Il protège le '
          'coffre localement et ne remplace pas votre mot de passe maître.',
        ),
        const SizedBox(height: 20),
        PasswordForm(
          formKey: _formKey,
          passwordController: _passwordController,
          passwordConfirmationController: _confirmationController,
        ),
        if (_viewModel.error != null) ...[
          const SizedBox(height: 16),
          Text(
            _viewModel.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        GradientElevatedButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Installer le coffre'),
        ),
      ],
    );
  }
}
