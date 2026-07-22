import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tonalité d'un état terminal : succès (vert) ou erreur (rouge).
enum PairingTone { success, error }

/// Affichage du **SAS** : le code court à comparer entre les deux appareils.
class PairingSasView extends StatelessWidget {
  const PairingSasView({required this.sas, this.footer, super.key});

  final String sas;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Vérifiez le code',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Ce code doit être identique sur les deux appareils. S'il diffère, annulez.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            sas,
            style: theme.textTheme.displaySmall?.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 24),
          Text(
            footer!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Affichage centré d'un état terminal (succès / erreur) : icône + titre +
/// message. La couleur de l'icône suit la [tone] (vert = succès, rouge = erreur).
class PairingStatusView extends StatelessWidget {
  const PairingStatusView({
    required this.icon,
    required this.title,
    required this.message,
    this.tone = PairingTone.error,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final PairingTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == PairingTone.success
        ? AppColors.success
        : theme.colorScheme.error;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
