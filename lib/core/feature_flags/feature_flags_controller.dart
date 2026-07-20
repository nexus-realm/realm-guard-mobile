import 'package:flutter/foundation.dart';

import 'feature_flag.dart';
import 'feature_flags_service.dart';

/// Source réactive des préférences de fonctionnalités ([FeatureFlag]), partagée
/// entre l'écran d'accueil et les paramètres.
///
/// Conservée en mémoire le temps de la session : un changement (ex. activer /
/// désactiver la gestion des TOTP) se répercute immédiatement sur l'interface,
/// sans redémarrage. Service longue durée injecté via le routeur (cf. DI
/// manuelle de `app_router.dart`).
class FeatureFlagsController extends ChangeNotifier {
  FeatureFlagsController({FeatureFlagsService? service})
    : _service = service ?? FeatureFlagsService();

  final FeatureFlagsService _service;

  // Optimiste : valeurs par défaut tant que le chargement n'a pas eu lieu, pour
  // éviter de masquer brièvement une fonctionnalité pendant la lecture du
  // stockage.
  final Map<FeatureFlag, bool> _states = <FeatureFlag, bool>{
    for (final flag in FeatureFlag.values) flag: flag.defaultEnabled,
  };

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// État courant d'une fonctionnalité.
  bool isEnabled(FeatureFlag flag) => _states[flag] ?? flag.defaultEnabled;

  /// Charge les préférences persistées. À appeler une fois au démarrage.
  Future<void> load() async {
    final loaded = await _service.loadAll();
    _states
      ..clear()
      ..addAll(loaded);
    _isLoaded = true;
    notifyListeners();
  }

  /// Active/désactive une fonctionnalité, persiste le choix et notifie les
  /// écouteurs. Aucune donnée associée n'est supprimée : la désactivation
  /// masque seulement l'interface correspondante.
  Future<void> setEnabled(FeatureFlag flag, bool enabled) async {
    if (_isLoaded && isEnabled(flag) == enabled) return;
    _states[flag] = enabled;
    notifyListeners();
    await _service.setEnabled(flag, enabled);
  }
}
