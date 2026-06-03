import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../data/custom_field.dart';
import '../viewmodels/credential_detail_view_model.dart';
import 'widgets/confirm_delete_dialog.dart';
import 'widgets/credential_avatar.dart';
import 'widgets/credential_form.dart';
import 'widgets/discard_changes_dialog.dart';

class CredentialDetailPage extends StatefulWidget {
  const CredentialDetailPage({
    required this.repository,
    required this.credentialId,
    super.key,
  });

  final CredentialEditor repository;
  final int credentialId;

  @override
  State<CredentialDetailPage> createState() => _CredentialDetailPageState();
}

class _CredentialDetailPageState extends State<CredentialDetailPage> {
  late final CredentialDetailViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _credentialFormKey = GlobalKey<CredentialFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = CredentialDetailViewModel(
      repository: widget.repository,
      credentialId: widget.credentialId,
    );
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasUnsavedChanges {
    final formState = _credentialFormKey.currentState;
    if (!_viewModel.isEditing || formState == null) return false;
    return _viewModel.hasChanges(formState.buildDraft());
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final draft = _credentialFormKey.currentState!.buildDraft();
    final ok = await _viewModel.save(draft);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant mis à jour.')),
      );
    } else {
      final message = _viewModel.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _cancelEditing() async {
    if (_hasUnsavedChanges && !await confirmDiscardChanges(context)) {
      return;
    }
    _viewModel.cancelEditing();
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: 'cet identifiant',
    );
    if (!confirmed) return;

    final ok = await _viewModel.delete();
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      final message = _viewModel.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _handlePopAttempt() async {
    final shouldDiscard = await confirmDiscardChanges(context);
    if (!shouldDiscard || !mounted) return;
    _viewModel.cancelEditing();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePopAttempt();
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    final isEditing = _viewModel.isEditing;
    final credential = _viewModel.current?.credential;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'identifiant' : 'Identifiant'),
        actions: [
          if (!isEditing && credential != null) ...[
            IconButton(
              tooltip: credential.favorite
                  ? 'Retirer des favoris'
                  : 'Ajouter aux favoris',
              icon: Icon(
                credential.favorite ? Icons.star : Icons.star_border,
              ),
              onPressed: _viewModel.toggleFavorite,
            ),
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit),
              onPressed: _viewModel.startEditing,
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              color: AppColors.destructive,
              onPressed: _viewModel.isSubmitting ? null : _delete,
            ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.notFound) {
      return const Center(child: Text('Cet identifiant n\'existe plus.'));
    }
    final credential = _viewModel.current?.credential;
    if (credential == null) {
      return const SizedBox.shrink();
    }

    return _viewModel.isEditing
        ? _buildEditView(credential)
        : _buildReadView(credential);
  }

  // --- Mode édition ---

  Widget _buildEditView(Credential credential) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CredentialForm(
            // Une clé liée à l'id force la recréation du form (et donc le
            // pré-remplissage) à chaque entrée en édition.
            key: _credentialFormKey,
            formKey: _formKey,
            profiles: _viewModel.profiles,
            initial: _viewModel.currentDraft,
            enabled: !_viewModel.isSubmitting,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 32),
          _buildEditActions(),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _viewModel.isSubmitting ? null : _cancelEditing,
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GradientElevatedButton(
            onPressed: _viewModel.isSubmitting ? null : _save,
            child: _viewModel.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }

  // --- Mode lecture seule ---

  Widget _buildReadView(Credential credential) {
    final profileName = _viewModel.current?.profile?.name;
    final customFields = CustomField.decode(credential.customFields);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              CredentialAvatar(
                title: credential.title,
                uri: credential.uri,
                radius: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  credential.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (credential.username != null)
          _ReadField(
            icon: Icons.person_outline,
            label: 'Nom d\'utilisateur',
            value: credential.username!,
            onCopy: () => _copy(credential.username!),
          ),
        if (credential.password != null)
          _ReadField(
            icon: Icons.lock_outline,
            label: 'Mot de passe',
            value: credential.password!,
            secret: true,
            onCopy: () => _copy(credential.password!),
          ),
        if (credential.uri != null)
          _ReadField(
            icon: Icons.link,
            label: 'Site / URL',
            value: credential.uri!,
            onCopy: () => _copy(credential.uri!),
            onOpen: () => _openUri(credential.uri!),
          ),
        if (credential.notes != null)
          _ReadField(
            icon: Icons.notes,
            label: 'Notes',
            value: credential.notes!,
          ),
        _ReadField(
          icon: Icons.person_pin_outlined,
          label: 'Profil associé',
          value: profileName ?? 'Sans profil',
        ),
        for (final field in customFields)
          _ReadField(
            icon: Icons.label_outline,
            label: field.label.isEmpty ? 'Champ' : field.label,
            value: field.value,
            secret: field.secret,
            onCopy: () => _copy(field.value),
          ),
      ],
    );
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse-papiers.')),
    );
  }

  Future<void> _openUri(String uri) async {
    final normalized = uri.startsWith('http') ? uri : 'https://$uri';
    final parsed = Uri.tryParse(normalized);
    if (parsed == null) return;
    final launched = await launchUrl(
      parsed,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }
}

/// Ligne d'affichage d'un champ en lecture seule, avec actions optionnelles
/// (copier, ouvrir) et masquage des valeurs secrètes.
class _ReadField extends StatefulWidget {
  const _ReadField({
    required this.icon,
    required this.label,
    required this.value,
    this.secret = false,
    this.onCopy,
    this.onOpen,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool secret;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  @override
  State<_ReadField> createState() => _ReadFieldState();
}

class _ReadFieldState extends State<_ReadField> {
  late bool _obscured = widget.secret;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayed = _obscured ? '••••••••' : widget.value;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: AppDecorations.surfaceCard(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, color: AppColors.secondaryText, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label.toUpperCase(), style: textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(displayed, style: textTheme.bodyLarge),
                ],
              ),
            ),
            if (widget.secret)
              IconButton(
                tooltip: _obscured ? 'Afficher' : 'Masquer',
                icon: Icon(
                  _obscured ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                color: AppColors.neutralAction,
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            if (widget.onOpen != null)
              IconButton(
                tooltip: 'Ouvrir',
                icon: const Icon(Icons.open_in_new, size: 20),
                color: AppColors.neutralAction,
                onPressed: widget.onOpen,
              ),
            if (widget.onCopy != null)
              IconButton(
                tooltip: 'Copier',
                icon: const Icon(Icons.copy, size: 20),
                color: AppColors.neutralAction,
                onPressed: widget.onCopy,
              ),
          ],
        ),
      ),
    );
  }
}
