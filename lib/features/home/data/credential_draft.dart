import 'custom_field.dart';

/// Données saisies pour créer ou modifier un identifiant.
///
/// Value object qui découple l'UI/les ViewModels de la forme exacte des
/// colonnes Drift (et stabilise la signature du repository).
class CredentialDraft {
  const CredentialDraft({
    required this.title,
    this.username,
    this.password,
    this.uri,
    this.notes,
    this.customFields = const [],
    this.favorite = false,
    this.profileId,
  });

  final String title;
  final String? username;
  final String? password;
  final String? uri;
  final String? notes;
  final List<CustomField> customFields;
  final bool favorite;
  final int? profileId;
}
