import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Niveau de sécurité estimé d'un mot de passe.
enum PasswordStrengthLevel { veryWeak, weak, fair, strong, veryStrong }

/// Évaluation de la force d'un mot de passe : un niveau, un libellé, une couleur
/// et un score normalisé (0..1) pour la barre.
///
/// Heuristique **locale** (aucune base de mots de passe compromis) basée sur la
/// longueur et la variété des classes de caractères. Volontairement simple et
/// déterministe ; destinée à guider l'utilisateur, pas à une garantie absolue.
class PasswordStrength {
  const PasswordStrength._(this.level, this.score);

  final PasswordStrengthLevel level;

  /// Score brut, de 0 (vide) à 5.
  final int score;

  /// Nombre de segments de la barre.
  static const int segmentCount = 4;

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrength._(PasswordStrengthLevel.veryWeak, 0);
    }

    var score = 0;

    // Longueur (le facteur le plus important).
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Variété des classes de caractères.
    var classes = 0;
    if (password.contains(RegExp(r'[a-z]'))) classes++;
    if (password.contains(RegExp(r'[A-Z]'))) classes++;
    if (password.contains(RegExp(r'[0-9]'))) classes++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) classes++;
    if (classes >= 3) score++;
    if (classes == 4) score++;

    // Pénalité : trop court quelle que soit la variété.
    if (password.length < 8) score = score.clamp(0, 1);

    return PasswordStrength._(_levelFromScore(score), score);
  }

  static PasswordStrengthLevel _levelFromScore(int score) {
    return switch (score) {
      <= 1 => PasswordStrengthLevel.veryWeak,
      2 => PasswordStrengthLevel.weak,
      3 => PasswordStrengthLevel.fair,
      4 => PasswordStrengthLevel.strong,
      _ => PasswordStrengthLevel.veryStrong,
    };
  }

  /// Nombre de segments allumés (0..[segmentCount]).
  int get filledSegments => switch (level) {
    PasswordStrengthLevel.veryWeak => 1,
    PasswordStrengthLevel.weak => 2,
    PasswordStrengthLevel.fair => 3,
    PasswordStrengthLevel.strong => 4,
    PasswordStrengthLevel.veryStrong => 4,
  };

  String get label => switch (level) {
    PasswordStrengthLevel.veryWeak => 'Très faible',
    PasswordStrengthLevel.weak => 'Faible',
    PasswordStrengthLevel.fair => 'Moyen',
    PasswordStrengthLevel.strong => 'Fort',
    PasswordStrengthLevel.veryStrong => 'Très fort',
  };

  Color get color => switch (level) {
    PasswordStrengthLevel.veryWeak => AppColors.error,
    PasswordStrengthLevel.weak => AppColors.orange,
    PasswordStrengthLevel.fair => AppColors.lightYellow,
    PasswordStrengthLevel.strong => AppColors.success,
    PasswordStrengthLevel.veryStrong => AppColors.success,
  };
}
