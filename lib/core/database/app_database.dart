import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class VaultEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get encryptedData => text()();
}

@DriftDatabase(tables: [VaultEntries])
class AppDatabase extends _$AppDatabase {

  AppDatabase(List<int> encryptionKeyBytes)
      : super(_openConnection(encryptionKeyBytes));

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection(List<int> encryptionKeyBytes) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'realm_guard_vault.sqlite'));

    // 1. Convertir les 32 octets de la clé en une chaîne hexadécimale de 64 caractères
    final hexKey = encryptionKeyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    return NativeDatabase(file, setup: (db) {
      db.execute("PRAGMA key = \"x'$hexKey'\";");
      db.execute("PRAGMA cipher_page_size = 4096;");
      db.execute("SELECT count(*) FROM sqlite_master;");
    });
  });
}