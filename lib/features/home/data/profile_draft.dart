/// Données saisies pour créer ou modifier un profil (identité réutilisable).
class ProfileDraft {
  const ProfileDraft({
    required this.name,
    this.emails = const [],
    this.usernames = const [],
    this.phoneNumbers = const [],
    this.color,
    this.note,
  });

  final String name;
  final List<String> emails;
  final List<String> usernames;
  final List<String> phoneNumbers;
  final int? color;
  final String? note;
}
