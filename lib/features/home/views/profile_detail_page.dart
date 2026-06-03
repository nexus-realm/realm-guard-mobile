import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/vault_repository.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../viewmodels/profile_detail_view_model.dart';
import 'widgets/delete_profile_dialog.dart';
import 'widgets/discard_changes_dialog.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({
    required this.repository,
    required this.profileId,
    super.key,
  });

  final ProfileEditor repository;
  final int profileId;

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late final ProfileDetailViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  List<TextEditingController> _emailControllers = [];

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileDetailViewModel(
      repository: widget.repository,
      profileId: widget.profileId,
    );
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _disposeEmailControllers();
    _viewModel.dispose();
    super.dispose();
  }

  void _disposeEmailControllers() {
    for (final controller in _emailControllers) {
      controller.dispose();
    }
  }

  void _onViewModelChanged() {
    final profile = _viewModel.current;
    if (profile != null && !_viewModel.isEditing) {
      _seedControllers();
    }
    if (mounted) setState(() {});
  }

  void _seedControllers() {
    _nameController.text = _viewModel.current?.name ?? '';
    _disposeEmailControllers();
    final emails = _viewModel.emails;
    _emailControllers = [
      for (final email in emails) TextEditingController(text: email),
      if (emails.isEmpty) TextEditingController(),
    ];
  }

  List<String> get _emailValues =>
      _emailControllers.map((c) => c.text).toList();

  bool get _hasUnsavedChanges =>
      _viewModel.isEditing &&
      _viewModel.hasChanges(name: _nameController.text, emails: _emailValues);

  void _addEmailField() {
    setState(() => _emailControllers.add(TextEditingController()));
  }

  void _removeEmailField(int index) {
    setState(() => _emailControllers.removeAt(index).dispose());
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final ok = await _viewModel.save(
      name: _nameController.text,
      emails: _emailValues,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
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
    _seedControllers();
    _viewModel.cancelEditing();
  }

  Future<void> _delete() async {
    final count = await _viewModel.linkedCredentialsCount();
    if (!mounted) return;

    final strategy = await DeleteProfileDialog.show(context, linkedCount: count);
    if (strategy == null || !mounted) return;

    final ok = await _viewModel.delete(strategy);
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
        title: Text(isEditing ? 'Modifier le profil' : 'Profil'),
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
      return const Center(child: Text('Ce profil n\'existe plus.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: _viewModel.isEditing && !_viewModel.isSubmitting,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Veuillez saisir un nom de profil.'
                  : null,
            ),
            const SizedBox(height: 24),
            Text('Emails', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._buildEmailFields(),
            const SizedBox(height: 32),
            if (_viewModel.isEditing) _buildEditActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailFields() {
    final isEditing = _viewModel.isEditing;

    if (!isEditing) {
      final emails = _viewModel.emails;
      if (emails.isEmpty) {
        return [
          Text(
            'Aucun email',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ];
      }
      return [
        for (final email in emails)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: Text(email),
          ),
      ];
    }

    return [
      for (var index = 0; index < _emailControllers.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailControllers[index],
                  enabled: !_viewModel.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email ${index + 1}'),
                ),
              ),
              if (_emailControllers.length > 1)
                IconButton(
                  tooltip: 'Supprimer cet email',
                  onPressed: _viewModel.isSubmitting
                      ? null
                      : () => _removeEmailField(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _viewModel.isSubmitting ? null : _addEmailField,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un email'),
        ),
      ),
    ];
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
