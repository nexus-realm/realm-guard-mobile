import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/wrapped_vault_key_store.dart';

/// Stockage de la VaultKey enrobée. Sa **présence** vaut marqueur « coffre migré
/// vers le modèle VaultKey » (`VaultMigrator`) : le contrat absent/présent est
/// donc aussi important que le contenu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SecureWrappedVaultKeyStore(FlutterSecureStorage());
  const wrapped = [1, 2, 3, 4];

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'read renvoie null tant que rien n\'est enrobé (état pré-migration)',
    () async {
      expect(await store.read(), isNull);
    },
  );

  test('write puis read restitue les octets à l\'identique', () async {
    await store.write(wrapped);

    expect(await store.read(), wrapped);
  });

  test('le blob est persisté en base64', () async {
    await store.write(wrapped);

    final raw = await const FlutterSecureStorage().read(
      key: 'wrapped_vault_key_v1',
    );
    expect(raw, base64Encode(wrapped));
  });

  test('une seconde écriture remplace la précédente (re-enrobage)', () async {
    await store.write(wrapped);

    await store.write(const [9, 9]);

    expect(await store.read(), const [9, 9]);
  });

  test('clear ramène à l\'état pré-migration', () async {
    await store.write(wrapped);

    await store.clear();

    expect(await store.read(), isNull);
  });
}
