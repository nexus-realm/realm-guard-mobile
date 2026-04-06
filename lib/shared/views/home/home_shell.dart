import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/neon_box_decoration.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final tabs = [AppRoutes.home, AppRoutes.home];

  bool get _isDeveloperCategoryEnabled {
    return kDebugMode ||
        const bool.fromEnvironment(
          'ENABLE_DEVELOPER_SETTINGS',
          defaultValue: false,
        );
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      context.go(tabs[index]);
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(
                    'Parametres',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  _buildSettingsCategory(
                    context: sheetContext,
                    title: 'General',
                    children: const [
                      ListTile(
                        leading: Icon(Icons.language),
                        title: Text('Langue'),
                        subtitle: Text('Configuration a venir'),
                        enabled: false,
                      ),
                      ListTile(
                        leading: Icon(Icons.palette_outlined),
                        title: Text('Theme'),
                        subtitle: Text('Configuration a venir'),
                        enabled: false,
                      ),
                    ],
                  ),
                  _buildSettingsCategory(
                    context: sheetContext,
                    title: 'Securite',
                    children: const [
                      ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Mot de passe maitre'),
                        subtitle: Text('Configuration a venir'),
                        enabled: false,
                      ),
                      ListTile(
                        leading: Icon(Icons.fingerprint),
                        title: Text('Biometrie'),
                        subtitle: Text('Configuration a venir'),
                        enabled: false,
                      ),
                    ],
                  ),
                  if (_isDeveloperCategoryEnabled)
                    _buildSettingsCategory(
                      context: sheetContext,
                      title: 'Developer',
                      children: [
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('Reset complet de l\'application'),
                          subtitle: const Text(
                            'Supprime les parametres, l\'etat onboarding et le coffre local.',
                          ),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _confirmAndResetAppState();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCategory({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndResetAppState() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset complet'),
          content: const Text(
            'Cette action va supprimer tous les parametres locaux et les donnees du coffre. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    try {
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      final supportDirectory = await getApplicationSupportDirectory();
      final filesToDelete = [
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite'),
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite-shm'),
        p.join(supportDirectory.path, 'realm_guard_vault.sqlite-wal'),
        p.join(supportDirectory.path, 'realmguard_security_metadata.salt'),
      ];

      for (final filePath in filesToDelete) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application reinitialisee.')),
      );
      context.go(AppRoutes.startup);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de reinitialiser les donnees pour le moment.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm Guard'),
        actions: [
          IconButton(
            tooltip: 'Parametres',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: widget.child),
          Container(
            height: 1,
            decoration: NeonBoxDecoration.neonBoxDecoration,
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.secondaryBackground,
        selectedItemColor: AppColors.mainColor,
        unselectedItemColor: AppColors.secondaryText,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil2'),
        ],
      ),
    );
  }
}
