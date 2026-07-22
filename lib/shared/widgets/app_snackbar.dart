import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Snackbars **cohérents** dans toute l'app. Trois intentions :
/// - [error] : rouge + icône (échec d'une action).
/// - [success] : accent vert + icône (action réussie).
/// - [info] : neutre (copie, information passive).
///
/// Centralise le style pour ne pas le réinventer sur chaque site — auparavant
/// seul l'écran de déverrouillage colorait ses erreurs, les autres passaient
/// inaperçues.
abstract final class AppSnackbar {
  static void success(BuildContext context, String message) => _show(
    context,
    message,
    icon: Icons.check_circle_outline,
    iconColor: AppColors.success,
  );

  static void error(BuildContext context, String message) => _show(
    context,
    message,
    background: AppColors.darkRed,
    icon: Icons.error_outline,
    iconColor: AppColors.lightRed,
  );

  static void info(BuildContext context, String message) =>
      _show(context, message);

  static void _show(
    BuildContext context,
    String message, {
    Color? background,
    IconData? icon,
    Color? iconColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background ?? AppColors.secondaryBackground,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.mainText),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
