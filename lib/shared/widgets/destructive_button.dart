import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bouton plein pour une action destructive (suppression, effacement…).
/// Centralise la couleur sémantique afin d'éviter de la répéter dans chaque
/// boîte de dialogue.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.destructive,
        foregroundColor: AppColors.black,
      ),
      child: child,
    );
  }
}
