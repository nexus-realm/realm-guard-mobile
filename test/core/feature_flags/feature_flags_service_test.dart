import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flag.dart';
import 'package:realm_guard_mobile/core/feature_flags/feature_flags_service.dart';

/// Secure storage en mémoire, branché sur la façade réelle [FlutterSecureStorage].
class FakeSecureStoragePlatform extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => store[key];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => store.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map<String, String>.of(store);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    store.clear();
  }
}

void main() {
  late FakeSecureStoragePlatform platform;
  late FeatureFlagsService service;

  setUp(() {
    platform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = platform;
    service = FeatureFlagsService();
  });

  group('FeatureFlagsService', () {
    test('renvoie la valeur par défaut du flag quand rien n\'est enregistré', () async {
      expect(
        await service.isEnabled(FeatureFlag.totp),
        FeatureFlag.totp.defaultEnabled,
      );
    });

    test('persiste la désactivation sous la clé du flag', () async {
      await service.setEnabled(FeatureFlag.totp, false);

      expect(await service.isEnabled(FeatureFlag.totp), isFalse);
      expect(platform.store[FeatureFlag.totp.storageKey], 'false');
    });

    test('persiste la réactivation', () async {
      await service.setEnabled(FeatureFlag.totp, false);
      await service.setEnabled(FeatureFlag.totp, true);

      expect(await service.isEnabled(FeatureFlag.totp), isTrue);
    });

    test('une valeur inattendue est interprétée comme désactivée', () async {
      platform.store[FeatureFlag.totp.storageKey] = 'oui';

      expect(await service.isEnabled(FeatureFlag.totp), isFalse);
    });

    test('loadAll couvre toutes les fonctionnalités connues', () async {
      final all = await service.loadAll();

      expect(all.keys, containsAll(FeatureFlag.values));
      for (final flag in FeatureFlag.values) {
        expect(all[flag], flag.defaultEnabled);
      }
    });
  });
}
