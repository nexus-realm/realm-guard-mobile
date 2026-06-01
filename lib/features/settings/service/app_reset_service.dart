import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Efface l'intégralité des données locales de l'application : secure storage
/// (clés, état onboarding, suivi de déverrouillage) + fichiers du coffre
/// chiffré + sel. Action irréversible.
///
/// Sous-classable pour les tests (les méthodes touchant la plateforme sont
/// surchargeables).
class AppResetService {
  AppResetService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const List<String> _vaultFiles = [
    'realm_guard_vault.sqlite',
    'realm_guard_vault.sqlite-shm',
    'realm_guard_vault.sqlite-wal',
    'realmguard_security_metadata.salt',
  ];

  /// Supprime toutes les données persistées. Le coffre doit avoir été fermé
  /// (verrouillé) au préalable pour libérer le fichier de base de données.
  Future<void> wipeAllData() async {
    await _secureStorage.deleteAll();

    final supportDirectory = await getApplicationSupportDirectory();
    for (final fileName in _vaultFiles) {
      final file = File(p.join(supportDirectory.path, fileName));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
