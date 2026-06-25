import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/security/keystore_key_guard.dart';

/// Efface l'intégralité des données locales de l'application : secure storage
/// (clés, état onboarding, suivi de déverrouillage), clé matérielle de l'Android
/// Keystore, fichiers du coffre chiffré + sel. Action irréversible.
///
/// Sous-classable pour les tests (les méthodes touchant la plateforme sont
/// surchargeables).
class AppResetService {
  AppResetService({
    FlutterSecureStorage? secureStorage,
    KeystoreKeyGuard? keyGuard,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _keyGuard = keyGuard ?? const KeystoreKeyGuard();

  final FlutterSecureStorage _secureStorage;
  final KeystoreKeyGuard _keyGuard;

  static const List<String> _vaultFiles = [
    'realm_guard_vault.sqlite',
    'realm_guard_vault.sqlite-shm',
    'realm_guard_vault.sqlite-wal',
    'realm_guard_vault.sqlite-journal',
    'realmguard_security_metadata.salt',
  ];

  /// Supprime toutes les données persistées. Le coffre doit avoir été fermé au
  /// préalable (cf. `VaultService.closeVault`) pour libérer le fichier de base.
  Future<void> wipeAllData() async {
    await _secureStorage.deleteAll();

    // Détruit la clé matérielle (Android Keystore) qui protégeait la clé
    // dérivée : sans cela elle survivrait à la suppression et serait réutilisée
    // au prochain enrôlement biométrique. Best-effort (cf. KeystoreKeyGuard).
    await _keyGuard.deleteKey();

    final supportDirectory = await getApplicationSupportDirectory();
    for (final fileName in _vaultFiles) {
      final file = File(p.join(supportDirectory.path, fileName));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
