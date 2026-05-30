import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/core/security/unlock_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';

/// In-memory secure storage backing the real [FlutterSecureStorage] facade.
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

class FakeVaultService extends VaultService {
  bool shouldSucceed = true;
  BiometricUnlockStatus biometricStatus = BiometricUnlockStatus.failed;

  @override
  Future<void> unlockWithMasterPassword(String masterPassword) async {
    if (!shouldSucceed) {
      throw Exception('mot de passe invalide');
    }
  }

  @override
  Future<BiometricUnlockStatus> unlockWithBiometrics() async => biometricStatus;
}

class FakeBiometricStorageService extends BiometricStorageService {
  FakeBiometricStorageService({this.available = false, this.enabled = false});

  bool available;
  bool enabled;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> isBiometricEnabled() async => enabled;
}

// Clés internes (miroir de UnlockService) pour seed/assertions.
const String _countKey = 'failed_attempts_count_v1';
const String _lockoutKey = 'lockout_timestamp_v1';
const String _bioFailKey = 'biometric_failures_count_v1';
const String _lastAttemptKey = 'last_failed_attempt_v1';
const String _lastKeyTimestampKey = 'last_key_timestamp_v1';
const String _lastBiometricPromptKey = 'last_biometric_prompt_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStoragePlatform storage;

  setUp(() {
    storage = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = storage;
  });

  UnlockService buildService(
    FakeVaultService vault, {
    FakeBiometricStorageService? bio,
  }) => UnlockService(
    biometricService: bio ?? FakeBiometricStorageService(),
    vaultService: vault,
    attemptCooldown: Duration.zero,
  );

  group('UnlockService - lockout & réinitialisation', () {
    test('verrouille après 5 tentatives échouées consécutives', () async {
      final service = buildService(FakeVaultService()..shouldSucceed = false);

      for (var i = 0; i < 4; i++) {
        final (result, locked) = await service.attemptPasswordUnlock('wrong');
        expect(result, UnlockAttemptResult.invalidPassword);
        expect(locked, isFalse, reason: 'tentative ${i + 1} ne doit pas verrouiller');
      }

      final (_, lockedAfterFifth) = await service.attemptPasswordUnlock('wrong');
      expect(lockedAfterFifth, isTrue);
      expect(storage.store.containsKey(_lockoutKey), isTrue);
    });

    test('réinitialise tout le suivi à la connexion réussie', () async {
      // Pré-état : des échecs récents (non périmés).
      storage.store[_countKey] = '3';
      storage.store[_bioFailKey] = '2';
      storage.store[_lastAttemptKey] = DateTime.now().toIso8601String();

      final service = buildService(FakeVaultService()..shouldSucceed = true);
      final (result, _) = await service.attemptPasswordUnlock('good');

      expect(result, UnlockAttemptResult.success);
      expect(storage.store.containsKey(_countKey), isFalse);
      expect(storage.store.containsKey(_lockoutKey), isFalse);
      expect(storage.store.containsKey(_bioFailKey), isFalse);
      expect(storage.store.containsKey(_lastAttemptKey), isFalse);
    });

    test('re-verrouille immédiatement si échec dans la fenêtre de reset', () async {
      // 5 échecs déjà comptés, dernière tentative il y a 6 min :
      // lockout (5 min) expiré mais fenêtre de reset (15 min) non écoulée.
      storage.store[_countKey] = '5';
      storage.store[_lastAttemptKey] =
          DateTime.now().subtract(const Duration(minutes: 6)).toIso8601String();

      final service = buildService(FakeVaultService()..shouldSucceed = false);
      final (result, isNowLocked) = await service.attemptPasswordUnlock('wrong');

      expect(result, UnlockAttemptResult.invalidPassword);
      expect(isNowLocked, isTrue, reason: 'comportement conservé : re-lock immédiat');
      expect(storage.store.containsKey(_lockoutKey), isTrue);
    });

    test('réinitialise le compteur après la fenêtre d\'inactivité', () async {
      // 5 échecs, mais dernière tentative il y a 16 min (> fenêtre de 15 min).
      storage.store[_countKey] = '5';
      storage.store[_lastAttemptKey] =
          DateTime.now().subtract(const Duration(minutes: 16)).toIso8601String();

      final service = buildService(FakeVaultService()..shouldSucceed = false);
      final (result, isNowLocked) = await service.attemptPasswordUnlock('wrong');

      expect(result, UnlockAttemptResult.invalidPassword);
      expect(isNowLocked, isFalse, reason: 'le compteur doit être reparti de zéro');
      expect(storage.store[_countKey], '1');
    });
  });

  group('UnlockService - échecs biométriques (S7)', () {
    test('un échec biométrique réel n\'alimente pas le lockout mot de passe', () async {
      final service = buildService(
        FakeVaultService()..biometricStatus = BiometricUnlockStatus.failed,
      );

      for (var i = 0; i < 6; i++) {
        final (result, locked) = await service.attemptBiometricUnlock();
        expect(result, UnlockAttemptResult.biometricFailed);
        expect(locked, isFalse);
      }

      // Le compteur biométrique monte, mais le lockout mot de passe est intact.
      expect(storage.store[_bioFailKey], '6');
      expect(storage.store.containsKey(_countKey), isFalse);
      expect(storage.store.containsKey(_lockoutKey), isFalse);
    });

    test('une annulation biométrique n\'est pas comptée', () async {
      final service = buildService(
        FakeVaultService()..biometricStatus = BiometricUnlockStatus.canceled,
      );

      final (result, locked) = await service.attemptBiometricUnlock();

      expect(result, UnlockAttemptResult.biometricFailed);
      expect(locked, isFalse);
      expect(storage.store.containsKey(_bioFailKey), isFalse);
      expect(storage.store.containsKey(_countKey), isFalse);
      expect(storage.store.containsKey(_lockoutKey), isFalse);
    });

    test('un succès biométrique réinitialise tout le suivi', () async {
      storage.store[_countKey] = '2';
      storage.store[_bioFailKey] = '1';
      final service = buildService(
        FakeVaultService()..biometricStatus = BiometricUnlockStatus.success,
      );

      final (result, ok) = await service.attemptBiometricUnlock();

      expect(result, UnlockAttemptResult.success);
      expect(ok, isTrue);
      expect(storage.store.containsKey(_countKey), isFalse);
      expect(storage.store.containsKey(_bioFailKey), isFalse);
    });
  });

  group('UnlockService - stratégie & seuil biométrique (S10)', () {
    test('repli sur mot de passe au seuil maxBiometricAttempts', () async {
      final nowIso = DateTime.now().toIso8601String();
      storage.store[_lastKeyTimestampKey] = nowIso;
      storage.store[_lastBiometricPromptKey] = nowIso;
      storage.store[_bioFailKey] = '${UnlockService.maxBiometricAttempts}';

      final service = buildService(
        FakeVaultService(),
        bio: FakeBiometricStorageService(available: true, enabled: true),
      );

      expect(await service.determineUnlockStrategy(), UnlockStrategy.password);
    });

    test('biométrie en dessous du seuil', () async {
      final nowIso = DateTime.now().toIso8601String();
      storage.store[_lastKeyTimestampKey] = nowIso;
      storage.store[_lastBiometricPromptKey] = nowIso;
      storage.store[_bioFailKey] = '0';

      final service = buildService(
        FakeVaultService(),
        bio: FakeBiometricStorageService(available: true, enabled: true),
      );

      expect(await service.determineUnlockStrategy(), UnlockStrategy.biometric);
    });
  });
}
