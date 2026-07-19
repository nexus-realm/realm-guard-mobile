import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

/// Résultat de la sélection de profil. Un objet (même avec `profileId == null`)
/// distingue « aucun profil choisi » d'une fermeture sans choix (→ `null`).
class ProfileChoice {
  const ProfileChoice(this.profileId);

  final int? profileId;
}

/// Bottom sheet de (ré)association de profil, **partagée** par les fiches
/// identifiant et TOTP (association inline, sans passer en mode édition).
/// Renvoie le choix, ou `null` si l'utilisateur ferme sans choisir.
Future<ProfileChoice?> showProfilePicker(
  BuildContext context, {
  required List<Profile> profiles,
  required int? currentId,
}) {
  return showModalBottomSheet<ProfileChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Aucun profil'),
            trailing: currentId == null
                ? const Icon(Icons.check, color: AppColors.mainColor)
                : null,
            onTap: () =>
                Navigator.of(sheetContext).pop(const ProfileChoice(null)),
          ),
          for (final profile in profiles)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(profile.name),
              trailing: currentId == profile.id
                  ? const Icon(Icons.check, color: AppColors.mainColor)
                  : null,
              onTap: () =>
                  Navigator.of(sheetContext).pop(ProfileChoice(profile.id)),
            ),
        ],
      ),
    ),
  );
}
