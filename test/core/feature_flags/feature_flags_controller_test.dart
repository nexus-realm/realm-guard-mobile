import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/feature_flags/feature_flag.dart';
import 'package:realmguard/core/feature_flags/feature_flags_controller.dart';

import '../../support/feature_flags_test_doubles.dart';

void main() {
  group('FeatureFlagsController', () {
    test('valeurs par défaut (optimiste) avant chargement', () {
      final controller = FeatureFlagsController(
        service: InMemoryFeatureFlagsService({FeatureFlag.totp: false}),
      );

      expect(controller.isEnabled(FeatureFlag.totp), isTrue);
      expect(controller.isLoaded, isFalse);
    });

    test('load() reflète les valeurs persistées et notifie', () async {
      final controller = FeatureFlagsController(
        service: InMemoryFeatureFlagsService({FeatureFlag.totp: false}),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.isEnabled(FeatureFlag.totp), isFalse);
      expect(controller.isLoaded, isTrue);
      expect(notifications, 1);
    });

    test('setEnabled persiste, met à jour et notifie', () async {
      final service = InMemoryFeatureFlagsService({FeatureFlag.totp: true});
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
      final service = InMemoryFeatureFlagsService({FeatureFlag.totp: true});
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
