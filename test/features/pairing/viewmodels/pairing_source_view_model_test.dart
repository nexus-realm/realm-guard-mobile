import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/pairing_source_view_model.dart';

class _FakeApi implements PairingApi {
  static final devicePk = Uint8List.fromList(List<int>.filled(32, 7));

  bool failSeal = false;
  bool failRegister = false;
  String? lastQr;
  String? lastAccountId;
  Uint8List? lastVaultKey;
  final List<Uint8List> registered = [];
  String? lastDeviceName;

  @override
  Future<PairingSession> startNewDevice() => throw UnimplementedError();

  @override
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) => throw UnimplementedError();

  @override
  Future<PairingSealOutcome> pairScannedDevice({
    required String qrPayload,
    required String accountId,
    required Uint8List vaultKey,
  }) async {
    if (failSeal) throw const PairingException.invalidQr();
    lastQr = qrPayload;
    lastAccountId = accountId;
    lastVaultKey = vaultKey;
    return PairingSealOutcome(sas: '654321', devicePublicKey: devicePk);
  }

  @override
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  }) async {
    if (failRegister) throw const PairingException.server();
    registered.add(devicePublicKey);
    lastDeviceName = name;
  }

  @override
  Future<void> authenticateDevice() => throw UnimplementedError();
}

void main() {
  final vaultKey = Uint8List.fromList([9, 9]);
  const account = '00000000-0000-0000-0000-000000000001';

  PairingSourceViewModel build(
    _FakeApi api, {
    Uint8List? Function()? vaultKeyProvider,
    Future<bool> Function()? authorize,
    Future<String> Function()? accountIdProvider,
  }) => PairingSourceViewModel(
    service: api,
    vaultKeyProvider: vaultKeyProvider ?? () => vaultKey,
    accountIdProvider: accountIdProvider ?? () async => account,
    authorize: authorize ?? () async => true,
  );

  test(
    'onQrScanned : autorisé → scelle et expose le SAS, sans inscrire',
    () async {
      final api = _FakeApi();
      final vm = build(api);

      await vm.onQrScanned('{"i":"r","q":"AAAA"}');

      expect(vm.sas, '654321');
      expect(vm.error, isNull);
      expect(api.lastVaultKey, vaultKey);
      expect(api.lastAccountId, account);
      // **Sécurité** : rien n'est inscrit tant que le SAS n'est pas confirmé.
      expect(api.registered, isEmpty);
      expect(vm.registered, isFalse);
    },
  );

  test("confirmSas → inscrit l'appareil au compte", () async {
    final api = _FakeApi();
    final vm = build(api);
    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    await vm.confirmSas();

    expect(api.registered, [_FakeApi.devicePk]);
    expect(api.lastDeviceName, isNotEmpty);
    expect(vm.registered, isTrue);
    expect(vm.error, isNull);
  });

  test('rejectSas → aucune inscription, alerte affichée', () async {
    final api = _FakeApi();
    final vm = build(api);
    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    vm.rejectSas();

    expect(api.registered, isEmpty);
    expect(vm.registered, isFalse);
    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
  });

  test('confirmSas sans SAS préalable → sans effet', () async {
    final api = _FakeApi();
    final vm = build(api);

    await vm.confirmSas();

    expect(api.registered, isEmpty);
    expect(vm.registered, isFalse);
  });

  test(
    "échec de l'inscription → message, appareil non marqué inscrit",
    () async {
      final api = _FakeApi()..failRegister = true;
      final vm = build(api);
      await vm.onQrScanned('{"i":"r","q":"AAAA"}');

      await vm.confirmSas();

      expect(vm.registered, isFalse);
      expect(vm.error, isNotNull);
    },
  );

  test(
    'coffre verrouillé (pas de VaultKey) → erreur, pas de scellage',
    () async {
      final api = _FakeApi();
      final vm = build(api, vaultKeyProvider: () => null);

      await vm.onQrScanned('{}');

      expect(vm.sas, isNull);
      expect(vm.error, isNotNull);
      expect(api.lastQr, isNull);
    },
  );

  test('biométrie refusée → erreur, pas de scellage', () async {
    final api = _FakeApi();
    final vm = build(api, authorize: () async => false);

    await vm.onQrScanned('{}');

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
    expect(api.lastQr, isNull);
  });

  test("échec du service → message d'erreur", () async {
    final api = _FakeApi()..failSeal = true;
    final vm = build(api);

    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
  });
}
