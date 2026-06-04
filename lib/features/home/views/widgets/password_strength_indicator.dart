import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/password_strength.dart';

/// Indicateur visuel de la force d'un mot de passe : barre segmentée colorée +
/// libellé. N'affiche rien si le mot de passe est vide.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = PasswordStrength.evaluate(password);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < PasswordStrength.segmentCount; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < PasswordStrength.segmentCount - 1
                          ? AppSpacing.xxs
                          : 0,
                    ),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < strength.filledSegments
                            ? strength.color
                            : AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sécurité : ${strength.label}',
              style: textTheme.labelMedium?.copyWith(color: strength.color),
            ),
          ),
        ],
      ),
    );
  }
}
