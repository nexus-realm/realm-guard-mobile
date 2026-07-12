import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feature_flags/feature_flag.dart';
import '../../../core/feature_flags/feature_flags_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/security/biometric_storage_service.dart';
import '../../../core/security/vault_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../autofill/viewmodels/autofill_settings_view_model.dart';
import '../../autofill/views/widgets/autofill_settings_tile.dart';
import '../service/app_reset_service.dart';
import '../viewmodels/settings_view_model.dart';
import 'widgets/delete_data_dialog.dart';
import 'widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.vaultService,
    required this.biometricService,
    required this.resetService,
    required this.featureFlagsController,
    super.key,
  });

  final VaultService vaultService;
  final BiometricStorageService biometricService;
  final AppResetService resetService;
  final FeatureFlagsController featureFlagsController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;
  final AutofillSettingsViewModel _autofillViewModel =
      AutofillSettingsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      biometricService: widget.biometricService,
      vaultService: widget.vaultService,
      resetService: widget.resetService,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _autofillViewModel.dispose();
    super.dispose();
  }

  Future<void> _onBiometricChanged(bool value) async {
    await _viewModel.setBiometricEnabled(value);
    if (!mounted) return;
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La biométrie sera active après votre prochaine saisie du mot de '
            'passe maître.',
          ),
        ),
      );
    }
  }

  void _lockNow() {
    _viewModel.lockNow();
    context.go(AppRoutes.unlock);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteDataDialog(),
    );
    if (confirmed != true) return;

    await _viewModel.deleteAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les données ont été supprimées.')),
    );
    context.go(AppRoutes.startup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildGeneralSection(),
                _buildFeaturesSection(),
                if (kDebugMode) _buildSyncSection(),
                _buildSecuritySection(),
                _buildAboutSection(),
                _buildDangerSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return const SettingsSection(
      title: 'Général',
      children: [
        ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Thème'),
          subtitle: Text('Bientôt disponible'),
          enabled: false,
        ),
        ListTile(
          leading: Icon(Icons.language),
          title: Text('Langue'),
          subtitle: Text('Bientôt disponible'),
          enabled: false,
        ),
      ],
    );
  }

  /// Section générique pilotée par le registre [FeatureFlag] : chaque
  /// fonctionnalité activable y apparaît automatiquement (aucun code par flag).
  Widget _buildFeaturesSection() {
    return ListenableBuilder(
      listenable: widget.featureFlagsController,
      builder: (context, _) {
        return SettingsSection(
          title: 'Fonctionnalités',
          children: [
            for (final flag in FeatureFlag.values)
              SwitchListTile(
                secondary: Icon(flag.icon),
                title: Text(flag.label),
                subtitle: Text(flag.description),
                value: widget.featureFlagsController.isEnabled(flag),
                onChanged: _viewModel.isBusy
                    ? null
                    : (value) {
                        widget.featureFlagsController.setEnabled(flag, value);
                      },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSyncSection() {
    return SettingsSection(
      title: 'Synchronisation',
      children: [
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Synchronisation multi-appareils'),
          subtitle: const Text('Chiffrée de bout en bout (bêta)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.settingsSync),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return SettingsSection(
      title: 'Sécurité',
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('Déverrouillage biométrique'),
          subtitle: Text(
            _viewModel.biometricAvailable
                ? 'Utiliser l\'empreinte ou le visage pour déverrouiller'
                : 'Indisponible sur cet appareil',
          ),
          value: _viewModel.biometricEnabled,
          onChanged: _viewModel.biometricAvailable && !_viewModel.isBusy
              ? _onBiometricChanged
              : null,
        ),
        AutofillSettingsTile(viewModel: _autofillViewModel),
        const ListTile(
          leading: Icon(Icons.timer_outlined),
          title: Text('Verrouillage automatique'),
          subtitle: Text('Bientôt disponible'),
          enabled: false,
        ),
        const ListTile(
          leading: Icon(Icons.password_outlined),
          title: Text('Re-demander le mot de passe maître'),
          subtitle: Text('Bientôt disponible'),
          enabled: false,
        ),
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Changer le mot de passe maître'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _viewModel.isBusy
              ? null
              : () => context.push(AppRoutes.settingsChangePassword),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Verrouiller maintenant'),
          onTap: _viewModel.isBusy ? null : _lockNow,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return SettingsSection(
      title: 'À propos',
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('À propos de l\'application'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.settingsAbout),
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return SettingsSection(
      title: 'Zone de danger',
      titleColor: AppColors.destructive,
      children: [
        ListTile(
          leading: const Icon(
            Icons.delete_forever,
            color: AppColors.destructive,
          ),
          title: const Text(
            'Supprimer toutes les données',
            style: TextStyle(color: AppColors.destructive),
          ),
          subtitle: const Text('Efface le coffre et tous les réglages'),
          onTap: _viewModel.isBusy ? null : _confirmDelete,
        ),
      ],
    );
  }
}
