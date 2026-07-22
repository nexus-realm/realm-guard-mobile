import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Carte de choix **cliquable** : icône accentuée + titre + sous-texte explicatif.
///
/// Brique commune des écrans de synchronisation (l'étape « en ligne » de
/// l'onboarding et Réglages → Synchronisation) pour présenter des options de
/// même niveau de manière lisible et cohérente.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Désactive l'interaction (ex. pendant une soumission) et grise la carte.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.secondaryBackground,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: AppColors.mainColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
