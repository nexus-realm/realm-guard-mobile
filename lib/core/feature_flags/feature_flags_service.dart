import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'feature_flag.dart';

/// Persistance générique des préférences de fonctionnalités (cf. [FeatureFlag]),
/// pour adapter l'interface à l'usage de chacun.
///
/// Stockage local uniquement (offline-first). Ces préférences ne sont pas
/// secrètes mais restent dans le secure storage par cohérence avec le reste de
/// l'application (et pour être effacées par la réinitialisation globale).
class FeatureFlagsService {
  FeatureFlagsService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  /// État d'une fonctionnalité (sa valeur par défaut si rien n'est enregistré).
  Future<bool> isEnabled(FeatureFlag flag) async {
    final value = await _secureStorage.read(key: flag.storageKey);
    if (value == null) return flag.defaultEnabled;
    return value == 'true';
  }

  /// Charge l'état de toutes les fonctionnalités connues en une fois.
  Future<Map<FeatureFlag, bool>> loadAll() async {
    final entries = await Future.wait(
      FeatureFlag.values.map(
        (flag) async => MapEntry(flag, await isEnabled(flag)),
      ),
    );
    return Map<FeatureFlag, bool>.fromEntries(entries);
  }

  /// Enregistre l'état d'une fonctionnalité. N'altère aucune donnée associée :
  /// la désactivation ne fait que masquer l'interface correspondante.
  Future<void> setEnabled(FeatureFlag flag, bool enabled) async {
    await _secureStorage.write(
      key: flag.storageKey,
      value: enabled ? 'true' : 'false',
    );
  }
}
