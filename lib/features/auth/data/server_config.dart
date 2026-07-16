/// Configuration du serveur de synchronisation.
class ServerConfig {
  /// URL de base **sans** slash final (ex. `http://10.0.2.2:8080`).
  final String baseUrl;

  const ServerConfig({required this.baseUrl});

  /// Configuration de développement.
  ///
  /// Défaut : `http://10.0.2.2:8080` — `10.0.2.2` est l'alias de la **machine hôte
  /// vu depuis l'émulateur Android** (le serveur tourne en local ; le docker-compose
  /// l'expose sur le port `8080` via Caddy).
  ///
  /// ⚠️ **Appareil physique** : `10.0.2.2` lui est inatteignable → surcharger l'URL
  /// au build avec l'IP LAN de la machine :
  /// ```
  /// flutter run --dart-define=RG_SERVER_URL=http://192.168.1.42:8080
  /// ```
  const ServerConfig.dev()
    : baseUrl = const String.fromEnvironment(
        'RG_SERVER_URL',
        defaultValue: 'http://10.0.2.2:8080',
      );
}
