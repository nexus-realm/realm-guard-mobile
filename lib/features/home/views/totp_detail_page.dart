import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_snackbar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/security/secure_clipboard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../data/totp_generator.dart';
import '../viewmodels/totp_detail_view_model.dart';
import 'widgets/confirm_delete_dialog.dart';
import 'widgets/detail_tile.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/profile_picker.dart';
import 'widgets/totp_form.dart';

class TotpDetailPage extends StatefulWidget {
  const TotpDetailPage({
    required this.repository,
    required this.totpId,
    super.key,
  });

  final TotpEditor repository;
  final int totpId;

  @override
  State<TotpDetailPage> createState() => _TotpDetailPageState();
}

class _TotpDetailPageState extends State<TotpDetailPage> {
  late final TotpDetailViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _totpFormKey = GlobalKey<TotpFormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = TotpDetailViewModel(
      repository: widget.repository,
      totpId: widget.totpId,
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

  /// Réassocie le profil directement depuis la lecture seule (sans mode édition),
  /// cohérent avec la fiche identifiant.
  Future<void> _selectProfile() async {
    final selected = await showProfilePicker(
      context,
      profiles: _viewModel.profiles,
      currentId: _viewModel.current?.totp.profileId,
    );
    if (selected == null || !mounted) return;
    final ok = await _viewModel.setProfile(selected.profileId);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Profil associé mis à jour.');
    } else {
      final message = _viewModel.errorMessage;
      if (message != null) {
        AppSnackbar.error(context, message);
      }
    }
  }

  bool get _hasUnsavedChanges {
    final formState = _totpFormKey.currentState;
    if (!_viewModel.isEditing || formState == null) return false;
    return _viewModel.hasChanges(formState.buildDraft());
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final draft = _totpFormKey.currentState!.buildDraft();
    final ok = await _viewModel.save(draft);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'TOTP mis à jour.');
    } else {
      _showError();
    }
  }

  Future<void> _cancelEditing() async {
    if (_hasUnsavedChanges && !await confirmDiscardChanges(context)) return;
    _viewModel.cancelEditing();
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: 'ce code TOTP',
    );
    if (!confirmed) return;

    final ok = await _viewModel.delete();
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      _showError();
    }
  }

  void _showError() {
    final message = _viewModel.errorMessage;
    if (message != null) {
      AppSnackbar.error(context, message);
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
        title: Text(isEditing ? 'Modifier le TOTP' : 'TOTP'),
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
      return const Center(child: Text('Ce code TOTP n\'existe plus.'));
    }
    final totp = _viewModel.current?.totp;
    if (totp == null) return const SizedBox.shrink();

    return _viewModel.isEditing ? _buildEditView() : _buildReadView(totp);
  }

  // --- Mode édition ---

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TotpForm(
            key: _totpFormKey,
            formKey: _formKey,
            profiles: _viewModel.profiles,
            initial: _viewModel.currentDraft,
            enabled: !_viewModel.isSubmitting,
            onChanged: () => setState(() {}),
          ),
          AppSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: _viewModel.isSubmitting ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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

  Widget _buildReadView(Totp totp) {
    final profileName = _viewModel.current?.profile?.name;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        _LiveCodeCard(totp: totp),
        DetailTile(
          icon: Icons.label_outline,
          label: 'Libellé',
          value: totp.label,
        ),
        if (totp.account != null)
          DetailTile(
            icon: Icons.person_outline,
            label: 'Compte',
            value: totp.account!,
          ),
        DetailTile(
          icon: Icons.person_pin_outlined,
          label: 'Profil associé',
          value: profileName ?? 'Sans profil',
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.neutralAction,
            tooltip: 'Modifier le profil associé',
            onPressed: _viewModel.isSubmitting ? null : _selectProfile,
          ),
        ),
        DetailTile(
          icon: Icons.tune,
          label: 'Paramètres',
          value:
              '${totp.digits} chiffres · ${totp.period}s · ${totp.algorithm}',
        ),
      ],
    );
  }
}

/// Grande carte affichant le code TOTP courant, rafraîchi en continu, avec
/// l'anneau de validité et un bouton copier.
class _LiveCodeCard extends StatefulWidget {
  const _LiveCodeCard({required this.totp});

  final Totp totp;

  @override
  State<_LiveCodeCard> createState() => _LiveCodeCardState();
}

class _LiveCodeCardState extends State<_LiveCodeCard> {
  Timer? _ticker;
  String _code = '';
  int _remaining = 0;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didUpdateWidget(_LiveCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totp.secret != widget.totp.secret ||
        oldWidget.totp.period != widget.totp.period ||
        oldWidget.totp.digits != widget.totp.digits ||
        oldWidget.totp.algorithm != widget.totp.algorithm) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final period = widget.totp.period;
    final remaining = TotpGenerator.remainingSeconds(period: period);
    final progress = TotpGenerator.progress(period: period);
    String code;
    try {
      code = await TotpGenerator.generate(
        secretBase32: widget.totp.secret,
        digits: widget.totp.digits,
        period: period,
        algorithm: totpAlgorithmFromName(widget.totp.algorithm),
      );
    } catch (_) {
      code = 'Secret invalide';
    }
    if (!mounted) return;
    setState(() {
      _code = code;
      _remaining = remaining;
      _progress = progress;
    });
  }

  String get _formattedCode {
    if (_code.length < 6) return _code;
    final mid = (_code.length / 2).ceil();
    return '${_code.substring(0, mid)} ${_code.substring(mid)}';
  }

  void _copy() {
    if (_code.isEmpty || _code == 'Secret invalide') return;
    const SecureClipboard().copySensitive(_code);
    AppSnackbar.info(
      context,
      'Code copié — presse-papiers vidé dans '
      '${SecureClipboard.clearDelay.inSeconds} s.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final urgent = _remaining <= 5;
    final color = urgent ? AppColors.error : AppColors.mainColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.surfaceCard(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formattedCode,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 34,
                  letterSpacing: 3,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1 - _progress,
                    strokeWidth: 3,
                    backgroundColor: AppColors.mainBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text('$_remaining', style: textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copier',
              icon: const Icon(Icons.copy),
              color: AppColors.neutralAction,
              onPressed: _copy,
            ),
          ],
        ),
      ),
    );
  }
}
