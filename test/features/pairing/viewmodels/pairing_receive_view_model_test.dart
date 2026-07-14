import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/pairing_receive_view_model.dart';

class _FakeApi implements PairingApi {
  bool failReceive = false;
  final receiptVaultKey = Uint8List.fromList([5, 5]);
  final receiptSas = '123456';

  @override
  PairingSession startNewDevice() => PairingSession(
    state: Uint8List.fromList([1]),
    relayId: 'relay',
    qrPayload: '{"i":"relay","q":"AAAA"}',
  );

  @override
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) async {
    if (failReceive) throw const PairingException.timeout();
    return PairingReceipt(vaultKey: receiptVaultKey, sas: receiptSas);
  }

  @override
  Future<String> pairScannedDevice({
    required String qrPayload,
    required Uint8List vaultKey,
  }) async => '000000';
}

void main() {
  test(
    'start affiche le QR puis expose le SAS + la VaultKey au succès',
    () async {
      final api = _FakeApi();
      final vm = PairingReceiveViewModel(service: api);

      await vm.start();

      expect(vm.qrPayload, contains('relay'));
      expect(vm.sas, api.receiptSas);
      expect(vm.vaultKey, api.receiptVaultKey);
      expect(vm.error, isNull);
      expect(vm.waiting, isFalse);
    },
  );

  test('start remonte une erreur de pairing (timeout)', () async {
    final api = _FakeApi()..failReceive = true;
    final vm = PairingReceiveViewModel(service: api);

    await vm.start();

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
    expect(vm.waiting, isFalse);
  });
}
