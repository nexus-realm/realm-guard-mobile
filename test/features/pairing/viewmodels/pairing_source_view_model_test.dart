import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/pairing_source_view_model.dart';

class _FakeApi implements PairingApi {
  bool failSeal = false;
  String? lastQr;
  Uint8List? lastVaultKey;

  @override
  PairingSession startNewDevice() => throw UnimplementedError();

  @override
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) => throw UnimplementedError();

  @override
  Future<String> pairScannedDevice({
    required String qrPayload,
    required Uint8List vaultKey,
  }) async {
    if (failSeal) throw const PairingException.invalidQr();
    lastQr = qrPayload;
    lastVaultKey = vaultKey;
    return '654321';
  }
}

void main() {
  final vaultKey = Uint8List.fromList([9, 9]);

  PairingSourceViewModel build(
    _FakeApi api, {
    Uint8List? Function()? vaultKeyProvider,
    Future<bool> Function()? authorize,
  }) => PairingSourceViewModel(
    service: api,
    vaultKeyProvider: vaultKeyProvider ?? () => vaultKey,
    authorize: authorize ?? () async => true,
  );

  test('onQrScanned : biométrie OK → scelle et expose le SAS', () async {
    final api = _FakeApi();
    final vm = build(api);

    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    expect(vm.sas, '654321');
    expect(vm.error, isNull);
    expect(api.lastVaultKey, vaultKey);
  });

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
