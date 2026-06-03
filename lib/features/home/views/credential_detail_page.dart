import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../viewmodels/credential_detail_view_model.dart';
import 'widgets/confirm_delete_dialog.dart';
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  int? _selectedProfileId;

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
    _titleController.dispose();
    _dataController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    // Pré-remplit les champs depuis l'enregistrement courant tant qu'on n'édite
    // pas (la première donnée chargée et toute mise à jour externe).
    final credential = _viewModel.current?.credential;
    if (credential != null && !_viewModel.isEditing) {
      _titleController.text = credential.title;
      _dataController.text = credential.encryptedData;
      _selectedProfileId = credential.profileId;
    }
    if (mounted) setState(() {});
  }

  bool get _hasUnsavedChanges =>
      _viewModel.isEditing &&
      _viewModel.hasChanges(
        title: _titleController.text,
        data: _dataController.text,
        profileId: _selectedProfileId,
      );

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final ok = await _viewModel.save(
      title: _titleController.text,
      data: _dataController.text,
      profileId: _selectedProfileId,
    );
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
    // Restaure les valeurs d'origine.
    final credential = _viewModel.current?.credential;
    if (credential != null) {
      _titleController.text = credential.title;
      _dataController.text = credential.encryptedData;
      _selectedProfileId = credential.profileId;
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
    context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'identifiant' : 'Identifiant'),
        actions: [
          if (!isEditing && _viewModel.current != null) ...[
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit),
              onPressed: _viewModel.startEditing,
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              enabled: _viewModel.isEditing && !_viewModel.isSubmitting,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Veuillez saisir un titre.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataController,
              enabled: _viewModel.isEditing && !_viewModel.isSubmitting,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Données',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileField(),
            const SizedBox(height: 32),
            if (_viewModel.isEditing) _buildEditActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField() {
    if (!_viewModel.isEditing) {
      final profileName = _viewModel.current?.profile?.name ?? 'Sans profil';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: const Text('Profil associé'),
        subtitle: Text(profileName),
      );
    }
    return DropdownButtonFormField<int?>(
      initialValue: _selectedProfileId,
      decoration: const InputDecoration(labelText: 'Profil associé (optionnel)'),
      items: [
        const DropdownMenuItem<int?>(child: Text('Aucun profil')),
        ..._viewModel.profiles.map(
          (Profile p) =>
              DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
        ),
      ],
      onChanged: _viewModel.isSubmitting
          ? null
          : (value) => setState(() => _selectedProfileId = value),
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
}
