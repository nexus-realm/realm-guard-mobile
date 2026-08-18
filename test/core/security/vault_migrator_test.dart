import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/vault_key_crypto.dart';
import 'package:realmguard/core/security/vault_migrator.dart';
import 'package:realmguard/core/security/wrapped_vault_key_store.dart';

/// Faux chiffreur : VaultKey fixe, "enrobage" réversible (préfixe 0xAA).
class _FakeCrypto implements VaultKeyCrypto {
  _FakeCrypto(this.log);

  final List<String> log;
  static final vk = Uint8List.fromList(List<int>.generate(32, (i) => i));

  @override
  Uint8List generate() {
    log.add('generate');
    return vk;
  }

  @override
  Uint8List wrap(List<int> kek, List<int> vaultKey) {
    log.add('wrap');
    return Uint8List.fromList([0xAA, ...vaultKey]);
  }

  @override
  Uint8List unwrap(List<int> kek, List<int> wrapped) =>
      Uint8List.fromList(wrapped.sublist(1));
}

/// Store de wrapped-VK en mémoire.
class _FakeStore implements WrappedVaultKeyStore {
  Uint8List? value;

  @override
  Future<Uint8List?> read() async => value;

  @override
  Future<void> write(List<int> wrapped) async =>
      value = Uint8List.fromList(wrapped);

  @override
  Future<void> clear() async => value = null;
}

/// Fausses opérations SQLCipher : journalisent, peuvent échouer au rekey.
class _FakeDb implements MigrationDb {
  _FakeDb(this.log, {this.failRekey = false});

  final List<String> log;
  final bool failRekey;

  @override
  Future<void> checkpoint() async => log.add('checkpoint');

  @override
  Future<void> rekey(List<int> newKey) async {
    log.add('rekey');
    if (failRekey) throw Exception('rekey a échoué');
  }

  @override
  Future<void> validate() async => log.add('validate');
}

/// Faux backup fichier : simule la présence d'un `.bak`.
class _FakeFiles implements VaultBackupFiles {
  _FakeFiles(this.log, {this.hasBackup = false});

  final List<String> log;
  bool hasBackup;

  @override
  Future<bool> backupExists() async => hasBackup;

  @override
  Future<void> backup() async {
    log.add('backup');
    hasBackup = true;
  }

  @override
  Future<void> restoreBackup() async {
    log.add('restore');
    hasBackup = false;
  }

  @override
  Future<void> deleteBackup() async {
    log.add('deleteBackup');
    hasBackup = false;
  }
}

void main() {
  group('heal (récupération)', () {
    test('ne fait rien sans sauvegarde', () async {
      final log = <String>[];
      await VaultMigrator(_FakeCrypto(log), _FakeStore()).heal(_FakeFiles(log));
      expect(log, isEmpty);
    });

    test(
      'finalise (supprime le .bak) si la wrapped-VK est présente → état B',
      () async {
        final log = <String>[];
        final store = _FakeStore()..value = Uint8List.fromList([1, 2, 3]);
        final files = _FakeFiles(log, hasBackup: true);
        await VaultMigrator(_FakeCrypto(log), store).heal(files);
        expect(log, ['deleteBackup']);
        expect(files.hasBackup, isFalse);
      },
    );

    test('restaure si la wrapped-VK est absente → état A', () async {
      final log = <String>[];
      final files = _FakeFiles(log, hasBackup: true);
      await VaultMigrator(_FakeCrypto(log), _FakeStore()).heal(files);
      expect(log, ['restore']);
      expect(files.hasBackup, isFalse);
    });
  });

  group('migrate', () {
    test(
      'suit l\'ordre sûr, stocke la wrapped-VK et renvoie la VaultKey',
      () async {
        final log = <String>[];
        final store = _FakeStore();
        final files = _FakeFiles(log);
        final vaultKey = await VaultMigrator(
          _FakeCrypto(log),
          store,
        ).migrate([9, 9], _FakeDb(log), files);

        expect(log, [
          'checkpoint',
          'backup',
          'generate',
          'rekey',
          'validate',
          'wrap',
          'deleteBackup',
        ]);
        expect(store.value, isNotNull); // wrapped-VK écrite
        expect(files.hasBackup, isFalse); // .bak supprimé
        expect(vaultKey, _FakeCrypto.vk); // renvoie la VaultKey
      },
    );

    test(
      'interrompue (rekey échoue) : garde le .bak, pas de wrapped-VK → état A',
      () async {
        final log = <String>[];
        final store = _FakeStore();
        final files = _FakeFiles(log);

        await expectLater(
          VaultMigrator(
            _FakeCrypto(log),
            store,
          ).migrate([9], _FakeDb(log, failRekey: true), files),
          throwsA(isA<Exception>()),
        );

        expect(store.value, isNull); // pas de wrapped-VK
        expect(files.hasBackup, isTrue); // .bak conservé → heal restaurera
      },
    );
  });
}
