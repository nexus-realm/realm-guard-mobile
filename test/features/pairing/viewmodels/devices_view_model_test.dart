import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/devices_service.dart';
import 'package:realmguard/features/pairing/viewmodels/devices_view_model.dart';

PairedDevice _device({
  String id = 'd1',
  String name = 'iPhone',
  bool revoked = false,
  bool isCurrent = false,
}) => PairedDevice(
  id: id,
  name: name,
  createdAt: DateTime.utc(2026),
  revoked: revoked,
  isCurrent: isCurrent,
);

class _FakeDevices implements DevicesApi {
  _FakeDevices({List<PairedDevice>? devices})
    : devices = devices ?? [_device()];

  List<PairedDevice> devices;
  bool failList = false;
  bool failAction = false;
  int listCalls = 0;
  final List<String> revoked = [];
  final List<(String, String)> renamed = [];

  @override
  Future<List<PairedDevice>> list() async {
    listCalls++;
    if (failList) throw const PairingException.sessionExpired();
    return devices;
  }

  @override
  Future<void> rename(String deviceId, String name) async {
    if (failAction) throw const PairingException.server();
    renamed.add((deviceId, name));
  }

  @override
  Future<void> revoke(String deviceId) async {
    if (failAction) throw const PairingException.server();
    revoked.add(deviceId);
  }
}

void main() {
  test('load expose la liste', () async {
    final api = _FakeDevices(
      devices: [
        _device(isCurrent: true),
        _device(id: 'd2', name: 'Laptop'),
      ],
    );
    final vm = DevicesViewModel(service: api);

    await vm.load();

    expect(vm.devices.length, 2);
    expect(vm.devices.first.isCurrent, isTrue);
    expect(vm.error, isNull);
    expect(vm.loading, isFalse);
  });

  test('load sans session → message, liste vide', () async {
    final api = _FakeDevices()..failList = true;
    final vm = DevicesViewModel(service: api);

    await vm.load();

    expect(vm.devices, isEmpty);
    expect(vm.error, isNotNull);
  });

  test('revoke révoque puis rafraîchit la liste', () async {
    final api = _FakeDevices();
    final vm = DevicesViewModel(service: api);
    await vm.load();

    final ok = await vm.revoke('d1');

    expect(ok, isTrue);
    expect(api.revoked, ['d1']);
    // La liste est rechargée pour refléter l'état serveur.
    expect(api.listCalls, 2);
  });

  test('rename applique le nom élagué', () async {
    final api = _FakeDevices();
    final vm = DevicesViewModel(service: api);

    final ok = await vm.rename('d1', '  Mon tel  ');

    expect(ok, isTrue);
    expect(api.renamed, [('d1', 'Mon tel')]);
  });

  test('rename refuse un nom vide sans appeler le service', () async {
    final api = _FakeDevices();
    final vm = DevicesViewModel(service: api);

    final ok = await vm.rename('d1', '   ');

    expect(ok, isFalse);
    expect(api.renamed, isEmpty);
    expect(vm.error, isNotNull);
  });

  test("échec d'une action → message, pas de crash", () async {
    final api = _FakeDevices()..failAction = true;
    final vm = DevicesViewModel(service: api);

    final ok = await vm.revoke('d1');

    expect(ok, isFalse);
    expect(vm.error, isNotNull);
    expect(vm.busy, isFalse);
  });
}
