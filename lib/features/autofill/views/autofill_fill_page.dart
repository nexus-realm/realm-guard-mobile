import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_elevated_button.dart';
import '../../home/views/widgets/credential_avatar.dart';
import '../../home/views/widgets/vault_list_tile.dart';
import '../service/autofill_gateway.dart';
import '../viewmodels/autofill_fill_view_model.dart';

/// Écran de remplissage automatique : déverrouille le coffre puis laisse
/// l'utilisateur choisir l'identifiant à renvoyer à l'application tierce.
class AutofillFillPage extends StatefulWidget {
  const AutofillFillPage({super.key});

  @override
  State<AutofillFillPage> createState() => _AutofillFillPageState();
}

class _AutofillFillPageState extends State<AutofillFillPage> {
  late final AutofillFillViewModel _viewModel;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _viewModel = AutofillFillViewModel(gateway: const PlatformAutofillGateway());
    _viewModel.addListener(_onChanged);
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm Guard'),
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
      case AutofillFillStage.loading:
      case AutofillFillStage.unlocking:
        return const _Centered(child: CircularProgressIndicator());
      case AutofillFillStage.submitting:
        return const _Centered(child: CircularProgressIndicator());
      case AutofillFillStage.needsPassword:
        return _buildPassword();
      case AutofillFillStage.picking:
        return _buildPicker();
      case AutofillFillStage.locked:
        return _buildMessage(
          Icons.lock_clock,
          'Trop de tentatives',
          'Réessayez plus tard depuis l\'application.',
        );
      case AutofillFillStage.invalidRequest:
        return _buildMessage(
          Icons.info_outline,
          'Remplissage automatique',
          'Cet écran s\'ouvre lorsqu\'une application demande un identifiant.',
        );
      case AutofillFillStage.error:
        return _buildMessage(
          Icons.error_outline,
          'Erreur',
          _viewModel.errorMessage ?? 'Une erreur est survenue.',
        );
    }
  }

  // --- Déverrouillage par mot de passe ---

  Widget _buildPassword() {
    final textTheme = Theme.of(context).textTheme;
    final domain = _viewModel.requestedDomain;
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
          if (domain != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'pour remplir sur $domain',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _submitPassword(),
            decoration: const InputDecoration(
              labelText: 'Mot de passe maître',
            ),
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

  // --- Choix de l'identifiant ---

  Widget _buildPicker() {
    final matched = _viewModel.matched;
    final source = _query.isEmpty
        ? _viewModel.all
        : _viewModel.all.where(_matchesQuery).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        if (_query.isEmpty && matched.isNotEmpty) ...[
          _sectionLabel(
            _viewModel.requestedDomain != null
                ? 'Suggestions pour ${_viewModel.requestedDomain}'
                : 'Suggestions',
          ),
          for (final credential in matched) _tile(credential),
          const Divider(height: AppSpacing.lg),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher un identifiant…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        _sectionLabel('Tous les identifiants'),
        if (source.isEmpty)
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              _query.isEmpty
                  ? 'Aucun identifiant enregistré.'
                  : 'Aucun résultat.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final credential in source) _tile(credential),
      ],
    );
  }

  bool _matchesQuery(Credential c) {
    bool has(String? v) => v != null && v.toLowerCase().contains(_query);
    return has(c.title) || has(c.username) || has(c.uri);
  }

  Widget _tile(Credential credential) {
    return VaultListTile(
      leading: CredentialAvatar(
        title: credential.title,
        uri: credential.uri,
        radius: 18,
      ),
      title: credential.title,
      subtitle: credential.username ?? credential.uri,
      onTap: () => _viewModel.select(credential),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  Widget _buildMessage(IconData icon, String title, String message) {
    final textTheme = Theme.of(context).textTheme;
    return _Centered(
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

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}
