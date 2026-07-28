import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/crdt_device_id_store.dart';

/// Identité d'appareil CRDT : 16 octets générés une fois puis **stables** (elle
/// départage les horloges HLC — la faire varier casserait l'ordre des écritures).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SecureCrdtDeviceIdStore(FlutterSecureStorage());

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('génère un identifiant de 16 octets au premier appel', () async {
    final id = await store.getOrCreate();

    expect(id, hasLength(16));
  });

  test('renvoie le même identifiant aux appels suivants', () async {
    final first = await store.getOrCreate();
    final second = await store.getOrCreate();

    expect(second, first);
  });

  test('relit l\'identifiant déjà persisté', () async {
    final persisted = List<int>.generate(16, (i) => i);
    FlutterSecureStorage.setMockInitialValues({
      'crdt_device_id_v1': base64.encode(persisted),
    });

    expect(await store.getOrCreate(), persisted);
  });

  test('régénère si la valeur persistée n\'a pas la bonne taille', () async {
    FlutterSecureStorage.setMockInitialValues({
      'crdt_device_id_v1': base64.encode(const [1, 2, 3]),
    });

    final id = await store.getOrCreate();

    expect(id, hasLength(16));
    expect(id, isNot(const [1, 2, 3]));
  });

  test('deux appareils tirent des identifiants différents', () async {
    final first = await store.getOrCreate();
    FlutterSecureStorage.setMockInitialValues({}); // « autre appareil »
    final second = await store.getOrCreate();

    expect(second, isNot(first));
  });
}
