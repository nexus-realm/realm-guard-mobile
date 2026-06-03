import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tuile « card » d'affichage en lecture seule : icône + libellé (petit, gris)
/// + valeur (claire), avec une action optionnelle en fin de ligne.
class DetailTile extends StatelessWidget {
  const DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondaryText, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: textTheme.bodyLarge),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
