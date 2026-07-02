import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../home/views/widgets/credential_form.dart';
import '../service/autofill_gateway.dart';
import '../viewmodels/autofill_save_view_model.dart';

/// Écran de sauvegarde : l'OS a proposé « Enregistrer dans Realm Guard » après
/// une connexion dans une app tierce. On déverrouille le coffre, on pré-remplit
/// un identifiant et on l'enregistre après confirmation.
class AutofillSavePage extends StatefulWidget {
  const AutofillSavePage({super.key});

  @override
  State<AutofillSavePage> createState() => _AutofillSavePageState();
}

class _AutofillSavePageState extends State<AutofillSavePage> {
  late final AutofillSaveViewModel _viewModel;
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<CredentialFormState> _credentialFormKey =
      GlobalKey<CredentialFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = AutofillSaveViewModel(gateway: const PlatformAutofillGateway());
    _viewModel.addListener(_onChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_viewModel.stage == AutofillSaveStage.saved) {
      SystemNavigator.pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer'),
        actions: [
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.stage) {
      case AutofillSaveStage.loading:
      case AutofillSaveStage.unlocking:
      case AutofillSaveStage.submitting:
      case AutofillSaveStage.saved:
        return const Center(child: CircularProgressIndicator());
      case AutofillSaveStage.needsPassword:
        return _buildPassword();
      case AutofillSaveStage.editing:
        return _buildEditor();
      case AutofillSaveStage.locked:
        return _buildMessage(
          Icons.lock_clock,
          'Trop de tentatives',
          'Réessayez plus tard depuis l\'application.',
        );
      case AutofillSaveStage.invalid:
        return _buildMessage(
          Icons.info_outline,
          'Rien à enregistrer',
          'Aucune donnée de connexion n\'a été détectée.',
        );
      case AutofillSaveStage.error:
        return _buildMessage(
          Icons.error_outline,
          'Erreur',
          _viewModel.errorMessage ?? 'Une erreur est survenue.',
        );
    }
  }

  Widget _buildPassword() {
    final textTheme = Theme.of(context).textTheme;
    final domain = _viewModel.domain;
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.lock_outline, size: 48, color: AppColors.mainColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Déverrouillez votre coffre',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            domain != null
                ? 'pour enregistrer l\'identifiant de $domain'
                : 'pour enregistrer ce nouvel identifiant',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _submitPassword(),
            decoration: const InputDecoration(labelText: 'Mot de passe maître'),
          ),
          if (_viewModel.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _viewModel.errorMessage!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          GradientElevatedButton(
            onPressed: _submitPassword,
            child: const Text('Déverrouiller'),
          ),
        ],
      ),
    );
  }

  void _submitPassword() {
    _viewModel.unlockWithPassword(_passwordController.text);
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vérifiez puis enregistrez',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          CredentialForm(
            key: _credentialFormKey,
            formKey: _formKey,
            profiles: _viewModel.profiles,
            initial: _viewModel.initialDraft,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientElevatedButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    final draft = _credentialFormKey.currentState!.buildDraft();
    await _viewModel.save(draft);
  }

  Widget _buildMessage(IconData icon, String title, String message) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
