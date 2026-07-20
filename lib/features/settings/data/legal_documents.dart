/// Document légal/informatif affiché en lecture seule.
class LegalDocument {
  const LegalDocument({required this.title, required this.body});

  final String title;
  final String body;
}

/// Contenus PLACEHOLDER à remplacer par les textes définitifs.
///
/// ⚠️ Ces textes n'ont aucune valeur juridique : ce sont des gabarits destinés
/// à être remplacés par le contenu réel (idéalement déplacés en assets une fois
/// finalisés).
abstract final class LegalDocuments {
  static const String _placeholderNotice =
      '[Document provisoire — contenu à rédiger avant la mise en production]';

  static const LegalDocument cgu = LegalDocument(
    title: 'Conditions générales d\'utilisation',
    body:
        '$_placeholderNotice\n\n'
        '1. Objet\n'
        'Les présentes conditions encadrent l\'utilisation de l\'application '
        'Realm Guard. Ce texte est un gabarit et doit être remplacé.\n\n'
        '2. Utilisation du service\n'
        'Realm Guard est un gestionnaire de mots de passe hors-ligne. '
        'L\'utilisateur est seul responsable de la conservation de son mot de '
        'passe maître.\n\n'
        '3. Responsabilité\n'
        'Contenu à compléter.\n',
  );

  static const LegalDocument privacy = LegalDocument(
    title: 'Politique de confidentialité',
    body:
        '$_placeholderNotice\n\n'
        'Realm Guard est conçue selon le principe « hors-ligne d\'abord ».\n\n'
        '• Aucune donnée n\'est transmise à un serveur.\n'
        '• Aucune télémétrie ni traçage.\n'
        '• Toutes les données sont chiffrées et stockées localement sur '
        'l\'appareil.\n\n'
        'Détails à compléter avant publication.\n',
  );

  static const LegalDocument legalNotice = LegalDocument(
    title: 'Mentions légales',
    body:
        '$_placeholderNotice\n\n'
        'Éditeur : à compléter.\n'
        'Contact : à compléter.\n'
        'Droits d\'utilisation : l\'application est fournie « en l\'état ». '
        'Le détail de la licence d\'utilisation sera précisé ici.\n',
  );
}
