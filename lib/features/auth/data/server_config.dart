/// Configuration du serveur de synchronisation.
class ServerConfig {
  /// URL de base **sans** slash final (ex. `http://10.0.2.2:8080`).
  final String baseUrl;

  const ServerConfig({required this.baseUrl});

  /// Défaut de développement : `10.0.2.2` = l'hôte de l'émulateur Android
  /// (le serveur tourne sur la machine de dev).
  const ServerConfig.dev() : baseUrl = 'http://10.0.2.2:8080';
}
