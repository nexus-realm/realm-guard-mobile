import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/vault_migrator.dart';

/// Sauvegarde fichier du coffre (`VaultFiles`) : c'est elle qui garantit qu'une
/// migration interrompue retombe toujours dans un état cohérent (A ou B). Testée
/// sur de vrais fichiers dans un dossier temporaire — aucun SQLCipher requis,
/// seul le `dart:io` compte ici.
void main() {
  late Directory dir;
  late String dbPath;
  late VaultFiles files;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rg_vault_files');
    dbPath = '${dir.path}/${VaultFiles.dbFileName}';
    files = VaultFiles(dbPath);
  });

  tearDown(() async => dir.delete(recursive: true));

  Future<void> writeDb(String content) => File(dbPath).writeAsString(content);
  Future<void> writeResidue(String suffix) =>
      File('$dbPath$suffix').writeAsString('résidu');
  File backup() => File('$dbPath.bak');

  test('vaultExists distingue coffre absent et présent', () async {
    expect(await files.vaultExists(), isFalse);

    await writeDb('coffre');

    expect(await files.vaultExists(), isTrue);
  });

  test(
    'backupExists est faux tant qu\'aucune migration n\'a démarré',
    () async {
      await writeDb('coffre');

      expect(await files.backupExists(), isFalse);
    },
  );

  test('backup copie le coffre sans le déplacer', () async {
    await writeDb('coffre v1');

    await files.backup();

    expect(await files.backupExists(), isTrue);
    expect(await backup().readAsString(), 'coffre v1');
    expect(await File(dbPath).readAsString(), 'coffre v1', reason: 'copie');
  });

  test(
    'restoreBackup ramène le coffre d\'origine et consomme la sauvegarde',
    () async {
      await writeDb('coffre v1');
      await files.backup();
      await writeDb('coffre à moitié re-chiffré'); // rekey interrompu

      await files.restoreBackup();

      expect(await File(dbPath).readAsString(), 'coffre v1');
      expect(await files.backupExists(), isFalse);
    },
  );

  test(
    'restoreBackup purge les résidus -wal / -shm du rekey partiel',
    () async {
      await writeDb('coffre v1');
      await files.backup();
      await writeResidue('-wal');
      await writeResidue('-shm');

      await files.restoreBackup();

      expect(await File('$dbPath-wal').exists(), isFalse);
      expect(await File('$dbPath-shm').exists(), isFalse);
    },
  );

  test('deleteBackup retire la sauvegarde', () async {
    await writeDb('coffre');
    await files.backup();

    await files.deleteBackup();

    expect(await files.backupExists(), isFalse);
    expect(await File(dbPath).exists(), isTrue, reason: 'coffre intact');
  });

  test('deleteBackup est idempotent (aucune sauvegarde)', () async {
    await expectLater(files.deleteBackup(), completes);
  });
}
