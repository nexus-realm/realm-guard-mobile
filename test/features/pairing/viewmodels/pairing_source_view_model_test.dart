import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/pairing_source_view_model.dart';

class _FakeApi implements PairingApi {
  static final devicePk = Uint8List.fromList(List<int>.filled(32, 7));

  bool failBegin = false;
  bool failSeal = false;
  String? lastQr;

  /// VaultKeys effectivement transmises. **Doit rester vide** tant que le SAS n'est
  /// pas confirmé : c'est la garantie du protocole en deux tours.
  final List<Uint8List> sealedVaultKeys = [];
  final List<Uint8List> registered = [];
  String? lastAccountId;
  String? lastDeviceName;

  @override
  Future<PairingSourceHandshake> beginPairing({
    required String qrPayload,
  }) async {
    if (failBegin) throw const PairingException.invalidQr();
    lastQr = qrPayload;
    return PairingSourceHandshake(
      state: Uint8List.fromList([1]),
      relayId: 'r',
      sas: '654321',
      devicePublicKey: devicePk,
    );
  }

  @override
  Future<void> sealVaultKey({
    required PairingSourceHandshake handshake,
    required String accountId,
    required Uint8List vaultKey,
  }) async {
    if (failSeal) throw const PairingException.server();
    lastAccountId = accountId;
    sealedVaultKeys.add(vaultKey);
  }

  @override
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  }) async {
    registered.add(devicePublicKey);
    lastDeviceName = name;
  }

  @override
  Future<PairingSession> startNewDevice() => throw UnimplementedError();

  @override
  Future<PairingHandshake> awaitSourceHello(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) => throw UnimplementedError();

  @override
  Future<PairingReceipt> awaitVaultKey(
    PairingSession session,
    PairingHandshake handshake, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) => throw UnimplementedError();

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

  test('tour 1 : expose le SAS sans rien transmettre ni inscrire', () async {
    final api = _FakeApi();
    final vm = build(api);

    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    expect(vm.sas, '654321');
    expect(vm.error, isNull);
    // **La garantie du deux tours** : ni VaultKey ni inscription avant confirmation.
    expect(api.sealedVaultKeys, isEmpty);
    expect(api.registered, isEmpty);
    expect(vm.completed, isFalse);
  });

  test('confirmSas → transmet la VaultKey puis inscrit', () async {
    final api = _FakeApi();
    final vm = build(api);
    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    await vm.confirmSas();

    expect(api.sealedVaultKeys, [vaultKey]);
    expect(api.lastAccountId, account);
    expect(api.registered, [_FakeApi.devicePk]);
    expect(api.lastDeviceName, isNotEmpty);
    expect(vm.completed, isTrue);
    expect(vm.error, isNull);
  });

  test('rejectSas → rien transmis, rien inscrit, alerte', () async {
    final api = _FakeApi();
    final vm = build(api);
    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    vm.rejectSas();

    expect(api.sealedVaultKeys, isEmpty);
    expect(api.registered, isEmpty);
    expect(vm.completed, isFalse);
    expect(vm.sas, isNull);
    expect(vm.error, contains('Aucune donnée transmise'));
  });

  test('confirmSas sans tour 1 → sans effet', () async {
    final api = _FakeApi();
    final vm = build(api);

    await vm.confirmSas();

    expect(api.sealedVaultKeys, isEmpty);
    expect(vm.completed, isFalse);
  });

  test("échec du scellage → message, pas d'inscription", () async {
    final api = _FakeApi()..failSeal = true;
    final vm = build(api);
    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    await vm.confirmSas();

    expect(vm.completed, isFalse);
    expect(vm.error, isNotNull);
    // L'inscription ne doit pas avoir lieu si le transfert a échoué.
    expect(api.registered, isEmpty);
  });

  test('coffre verrouillé (pas de VaultKey) → erreur, pas de tour 1', () async {
    final api = _FakeApi();
    final vm = build(api, vaultKeyProvider: () => null);

    await vm.onQrScanned('{}');

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
    expect(api.lastQr, isNull);
  });

  test('biométrie refusée → erreur, pas de tour 1', () async {
    final api = _FakeApi();
    final vm = build(api, authorize: () async => false);

    await vm.onQrScanned('{}');

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
    expect(api.lastQr, isNull);
  });

  test("échec du service → message d'erreur", () async {
    final api = _FakeApi()..failBegin = true;
    final vm = build(api);

    await vm.onQrScanned('{"i":"r","q":"AAAA"}');

    expect(vm.sas, isNull);
    expect(vm.error, isNotNull);
  });
}
