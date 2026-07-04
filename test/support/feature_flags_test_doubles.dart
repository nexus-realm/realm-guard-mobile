import 'package:realmguard/core/feature_flags/feature_flag.dart';
import 'package:realmguard/core/feature_flags/feature_flags_controller.dart';
import 'package:realmguard/core/feature_flags/feature_flags_service.dart';

/// Service de feature flags en mémoire (aucun accès plateforme), pour les tests.
class InMemoryFeatureFlagsService extends FeatureFlagsService {
  InMemoryFeatureFlagsService([Map<FeatureFlag, bool>? initial])
    : _store = <FeatureFlag, bool>{...?initial};

  final Map<FeatureFlag, bool> _store;
  int writeCount = 0;

  @override
  Future<bool> isEnabled(FeatureFlag flag) async =>
      _store[flag] ?? flag.defaultEnabled;

  @override
  Future<Map<FeatureFlag, bool>> loadAll() async => <FeatureFlag, bool>{
    for (final flag in FeatureFlag.values)
      flag: _store[flag] ?? flag.defaultEnabled,
  };

  @override
  Future<void> setEnabled(FeatureFlag flag, bool enabled) async {
    _store[flag] = enabled;
    writeCount++;
  }
}

/// Contrôleur de feature flags adossé à un stockage en mémoire (non chargé).
FeatureFlagsController featureFlagsControllerWith([
  Map<FeatureFlag, bool>? initial,
]) => FeatureFlagsController(service: InMemoryFeatureFlagsService(initial));
