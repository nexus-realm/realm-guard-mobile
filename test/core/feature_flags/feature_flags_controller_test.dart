import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flag.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flags_controller.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flags_service.dart';

/// Service de préférences en mémoire (aucun accès plateforme).
class FakeFeatureFlagsService extends FeatureFlagsService {
  FakeFeatureFlagsService(this._states);

  final Map<FeatureFlag, bool> _states;
  int writeCount = 0;

  @override
  Future<bool> isEnabled(FeatureFlag flag) async =>
      _states[flag] ?? flag.defaultEnabled;

  @override
  Future<Map<FeatureFlag, bool>> loadAll() async =>
      Map<FeatureFlag, bool>.of(_states);

  @override
  Future<void> setEnabled(FeatureFlag flag, bool enabled) async {
    _states[flag] = enabled;
    writeCount++;
  }
}

void main() {
  group('FeatureFlagsController', () {
    test('valeurs par défaut (optimiste) avant chargement', () {
      final controller = FeatureFlagsController(
        service: FakeFeatureFlagsService({FeatureFlag.totp: false}),
      );

      expect(controller.isEnabled(FeatureFlag.totp), isTrue);
      expect(controller.isLoaded, isFalse);
    });

    test('load() reflète les valeurs persistées et notifie', () async {
      final controller = FeatureFlagsController(
        service: FakeFeatureFlagsService({FeatureFlag.totp: false}),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.isEnabled(FeatureFlag.totp), isFalse);
      expect(controller.isLoaded, isTrue);
      expect(notifications, 1);
    });

    test('setEnabled persiste, met à jour et notifie', () async {
      final service = FakeFeatureFlagsService({FeatureFlag.totp: true});
      final controller = FeatureFlagsController(service: service);
      await controller.load();

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setEnabled(FeatureFlag.totp, false);

      expect(controller.isEnabled(FeatureFlag.totp), isFalse);
      expect(service.writeCount, 1);
      expect(notifications, 1);
    });

    test('setEnabled ignore une valeur identique après chargement', () async {
      final service = FakeFeatureFlagsService({FeatureFlag.totp: true});
      final controller = FeatureFlagsController(service: service);
      await controller.load();

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setEnabled(FeatureFlag.totp, true);

      expect(service.writeCount, 0);
      expect(notifications, 0);
    });
  });
}
