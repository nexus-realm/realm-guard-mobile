import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../viewmodels/profile_detail_view_model.dart';
import 'widgets/delete_profile_dialog.dart';
import 'widgets/detail_tile.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/profile_form.dart';

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
  final _profileFormKey = GlobalKey<ProfileFormState>();

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
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasUnsavedChanges {
    final formState = _profileFormKey.currentState;
    if (!_viewModel.isEditing || formState == null) return false;
    return _viewModel.hasChanges(formState.buildDraft());
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final draft = _profileFormKey.currentState!.buildDraft();
    final ok = await _viewModel.save(draft);
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
      return const Center(child: Text('Ce profil n\'existe plus.'));
    }
    final profile = _viewModel.current;
    if (profile == null) return const SizedBox.shrink();

    return _viewModel.isEditing
        ? _buildEditView()
        : _buildReadView(profile);
  }

  // --- Mode édition ---

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileForm(
            key: _profileFormKey,
            formKey: _formKey,
            initial: _viewModel.currentDraft,
            enabled: !_viewModel.isSubmitting,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 32),
          Row(
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
          ),
        ],
      ),
    );
  }

  // --- Mode lecture seule ---

  Widget _buildReadView(Profile profile) {
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
              ProfileAvatar(
                name: profile.name,
                colorValue: profile.color,
                radius: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        ..._section('Emails', Icons.email_outlined, _viewModel.emails),
        ..._section(
          'Noms d\'utilisateur',
          Icons.person_outline,
          _viewModel.usernames,
        ),
        ..._section('Téléphones', Icons.phone_outlined, _viewModel.phoneNumbers),
        if ((profile.note ?? '').isNotEmpty)
          DetailTile(
            icon: Icons.notes,
            label: 'Note',
            value: profile.note!,
          ),
      ],
    );
  }

  List<Widget> _section(String label, IconData icon, List<String> values) {
    return [
      for (final value in values)
        DetailTile(icon: icon, label: label, value: value),
    ];
  }
}
