import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/vault_list_tile.dart';

/// Page de gestion des profils, accessible depuis l'AppBar de la Vault.
///
/// Les profils sont des données de référence (créées/modifiées rarement) : ils
/// vivent dans un écran dédié, hors du flux de consultation quotidien des
/// secrets (identifiants, TOTP, …).
class ProfilesPage extends StatelessWidget {
  const ProfilesPage({required this.repository, super.key});

  final HomeRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profils')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addProfile),
        icon: const Icon(Icons.add),
        label: const Text('Profil'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Profile>>(
          stream: repository.watchAllProfiles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profiles = snapshot.data ?? const [];
            if (profiles.isEmpty) {
              return const _EmptyProfiles();
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final subtitle = _profileSubtitle(profile);
                return VaultListTile(
                  leading: ProfileAvatar(
                    name: profile.name,
                    colorValue: profile.color,
                  ),
                  title: profile.name,
                  subtitle: subtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('${AppRoutes.profileDetail}/${profile.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Résumé affiché sous le nom : 1er email + compteur, sinon « Profil ».
  String _profileSubtitle(Profile profile) {
    final emails = _decodeList(profile.emails);
    if (emails.isEmpty) return 'Profil';
    if (emails.length == 1) return emails.first;
    return '${emails.first} +${emails.length - 1}';
  }

  List<String> _decodeList(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {
      // Ignore le format inattendu.
    }
    return const [];
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun profil',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Appuyez sur + pour créer un profil et y associer vos '
              'identifiants.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
