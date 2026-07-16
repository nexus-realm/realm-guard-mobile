import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/pairing_receive_view_model.dart';

class _FakeApi implements PairingApi {
  bool failReceive = false;
  final receiptVaultKey = Uint8List.fromList([5, 5]);
  final receiptSas = '123456';
  final receiptAccountId = '00000000-0000-0000-0000-000000000001';

  @override
  Future<PairingSession> startNewDevice() async => PairingSession(
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
    return PairingReceipt(
      vaultKey: receiptVaultKey,
      accountId: receiptAccountId,
      sas: receiptSas,
    );
  }

  @override
  Future<PairingSealOutcome> pairScannedDevice({
    required String qrPayload,
    required String accountId,
    required Uint8List vaultKey,
  }) async => PairingSealOutcome(
    sas: '000000',
    devicePublicKey: Uint8List.fromList([0]),
  );

  @override
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  }) async {}

  @override
  Future<void> authenticateDevice() async {}
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
