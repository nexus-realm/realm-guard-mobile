import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../service/app_info_service.dart';
import 'widgets/settings_section.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  static const String _sourceUrl =
      'https://github.com/nexus-realm/realm-guard-mobile';

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<AppInfo> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = const AppInfoService().load();
  }

  Future<void> _openSource() async {
    final uri = Uri.parse(AboutPage._sourceUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: SafeArea(
        child: FutureBuilder<AppInfo>(
          future: _infoFuture,
          builder: (context, snapshot) {
            final info = snapshot.data;
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                const _PrivacyBanner(),
                SettingsSection(
                  title: 'Application',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Version'),
                      subtitle: Text(
                        info == null
                            ? 'Chargement…'
                            : '${info.version} (build ${info.buildNumber})',
                      ),
                    ),
                    if (info != null)
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Identifiant'),
                        subtitle: Text(info.packageName),
                      ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Code source'),
                      subtitle: const Text('Voir le projet sur GitHub'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: _openSource,
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Légal',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Politique de confidentialité'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.settingsPrivacy),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Conditions d\'utilisation'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.settingsCgu),
                    ),
                    ListTile(
                      leading: const Icon(Icons.gavel_outlined),
                      title: const Text('Mentions légales'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.settingsLegal),
                    ),
                    ListTile(
                      leading: const Icon(Icons.workspaces_outline),
                      title: const Text('Licences open-source'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: info?.appName ?? 'Realm Guard',
                        applicationVersion: info?.version,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('100% hors-ligne', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Aucune donnée ne quitte votre appareil, aucune télémétrie.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
