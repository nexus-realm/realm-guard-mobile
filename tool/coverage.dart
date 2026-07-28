// Mesure de couverture **honnête**.
//
// Deux corrections par rapport à `flutter test --coverage` brut :
//  1. le code **généré** (drift `*.g.dart`, bindings FFI `lib/src/rust/`) est
//     retiré du rapport — instrumenté mais jamais testé, il écrasait le score ;
//  2. `test/all_imports_test.dart` (cf. tool/gen_coverage_imports.dart) force
//     tous les fichiers de `lib/` dans le rapport, sinon les fichiers qu aucun
//     test n importe sont **absents** au lieu d être comptés à 0 %.
//
// Usage :
//   dart run tool/coverage.dart            # relance les tests puis analyse
//   dart run tool/coverage.dart --no-run   # analyse le lcov.info existant
//
// Note : le lcov est **réécrit filtré** sur place. Le détail « hors périmètre »
// n'apparaît donc qu'au premier passage ; un `--no-run` enchaîné relit un fichier
// déjà filtré et affiche le même pourcentage, sans la ventilation.
library;

import 'dart:io';

const _lcovPath = 'coverage/lcov.info';

/// Fichiers **structurellement inatteignables** depuis `flutter test` (VM Dart :
/// ni SQLCipher, ni lib Rust, ni canaux plateforme) ou sans logique à couvrir.
///
/// Règle d'admission — un fichier n'entre ici que si **aucun** test hôte ne peut
/// l'exécuter, pas parce qu'il n'est « pas encore testé ». Un fichier testable
/// mais non couvert doit rester dans le périmètre et apparaître à 0 %.
/// Ces fichiers relèvent du **smoke on-device** (cf. docs/AGENTS.md §11).
const _outOfScope = <String, String>{
  // Racine de composition : instanciation de services + déclarations de routes,
  // aucune logique — un test ne ferait que réécrire le câblage.
  'lib/main.dart': 'point d\'entrée (verrou portrait, override SQLCipher)',
  'lib/core/routes/app_router.dart': 'racine de composition (DI + GoRouter)',

  // Canaux plateforme : le binding de test ne répond jamais.
  'lib/core/security/biometric_storage_service.dart':
      'local_auth + Keystore Android',
  'lib/core/security/keystore_key_guard.dart':
      'clé matérielle Keystore Android',

  // SQLCipher : absent du binaire de test hôte (PRAGMA key).
  'lib/core/security/vault_service.dart': 'ouverture SQLCipher (PRAGMA key)',

  // Délégation pure aux bindings FFI générés : la lib native n'est pas chargée.
  'lib/core/sync/crdt_ffi.dart': 'passe-plat vers la lib Rust (FFI)',
  'lib/core/security/vault_key_crypto.dart':
      'passe-plat vers la lib Rust (FFI)',

  // DSL de schéma drift : déclarations de colonnes, rien à exécuter.
  'lib/core/database/models/credentials.dart': 'déclaration de table drift',
  'lib/core/database/models/totps.dart': 'déclaration de table drift',
  'lib/core/database/models/profiles.dart': 'déclaration de table drift',
  'lib/core/database/models/crdt_docs.dart': 'déclaration de table drift',
  'lib/core/database/models/pending_deltas.dart': 'déclaration de table drift',
};

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') || path.contains('/src/rust/');

/// Chemin normalisé `lib/...` (le lcov porte des chemins absolus Windows).
String _relative(String path) {
  final index = path.indexOf('lib/');
  return index == -1 ? path : path.substring(index);
}

/// Regroupe par zone (`lib/<a>/<b>`) pour lire la couverture par couche.
String _zone(String path) {
  final index = path.indexOf('lib/');
  final relative = index == -1 ? path : path.substring(index + 4);
  final parts = relative.split('/');
  return parts.length > 1 ? 'lib/${parts[0]}/${parts[1]}' : 'lib/$relative';
}

Future<void> main(List<String> args) async {
  if (!args.contains('--no-run')) {
    final process = await Process.start(
      'flutter',
      ['test', '--coverage'],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) exit(code);
  }

  final lcov = File(_lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('$_lcovPath introuvable — lance sans --no-run.');
    exit(1);
  }

  // Un enregistrement lcov = "SF:<fichier> … end_of_record".
  final records = lcov
      .readAsStringSync()
      .split('end_of_record')
      .where((record) => record.contains('SF:'));

  final kept = <String>[];
  final found = <String, int>{};
  final hit = <String, int>{};
  // Hors périmètre : compté à part, jamais silencieusement effacé.
  final skippedFound = <String, int>{};
  final skippedHit = <String, int>{};
  var generatedCount = 0;

  for (final record in records) {
    final lines = record.trim().split('\n').map((l) => l.trim()).toList();
    final source = lines
        .firstWhere((l) => l.startsWith('SF:'))
        .substring(3)
        .replaceAll('\\', '/');
    if (_isGenerated(source)) {
      generatedCount++;
      continue;
    }
    final relative = _relative(source);
    final excluded = _outOfScope.containsKey(relative);
    final foundBucket = excluded ? skippedFound : found;
    final hitBucket = excluded ? skippedHit : hit;
    if (!excluded) kept.add('${record.trim()}\nend_of_record');
    for (final line in lines.where((l) => l.startsWith('DA:'))) {
      final parts = line.substring(3).split(',');
      final key = excluded ? relative : source;
      foundBucket[key] = (foundBucket[key] ?? 0) + 1;
      if (int.parse(parts[1]) > 0) hitBucket[key] = (hitBucket[key] ?? 0) + 1;
    }
  }

  // Réécrit le lcov filtré : tout consommateur en aval voit la donnée honnête.
  lcov.writeAsStringSync('${kept.join('\n')}\n');

  final zoneFound = <String, int>{};
  final zoneHit = <String, int>{};
  for (final source in found.keys) {
    final zone = _zone(source);
    zoneFound[zone] = (zoneFound[zone] ?? 0) + found[source]!;
    zoneHit[zone] = (zoneHit[zone] ?? 0) + (hit[source] ?? 0);
  }

  final totalFound = found.values.fold(0, (a, b) => a + b);
  final totalHit = hit.values.fold(0, (a, b) => a + b);
  final percent = totalFound == 0 ? 0.0 : 100 * totalHit / totalFound;

  final skippedLines = skippedFound.values.fold(0, (a, b) => a + b);
  final skippedCovered = skippedHit.values.fold(0, (a, b) => a + b);
  final rawFound = totalFound + skippedLines;
  final rawHit = totalHit + skippedCovered;
  final rawPercent = rawFound == 0 ? 0.0 : 100 * rawHit / rawFound;

  stdout
    ..writeln('')
    ..writeln(
      'Fichiers mesurés : ${found.length}'
      '  (généré exclu : $generatedCount,'
      ' hors périmètre : ${skippedFound.length})',
    )
    ..writeln(
      'COUVERTURE (périmètre testable) : $totalHit/$totalFound = '
      '${percent.toStringAsFixed(1)} %',
    )
    ..writeln(
      'Brut, hors périmètre inclus      : $rawHit/$rawFound = '
      '${rawPercent.toStringAsFixed(1)} %',
    )
    ..writeln('');

  final zones = zoneFound.keys.toList()
    ..sort((a, b) => zoneFound[b]!.compareTo(zoneFound[a]!));
  stdout.writeln('${'ZONE'.padRight(32)}${'COUV.'.padLeft(7)}   lignes');
  for (final zone in zones) {
    final f = zoneFound[zone]!;
    final h = zoneHit[zone] ?? 0;
    final p = (100 * h / f).toStringAsFixed(1).padLeft(6);
    stdout.writeln('${zone.padRight(32)}$p %   $h/$f');
  }

  // Fichiers sans aucune ligne couverte : la cible la plus rentable.
  final untouched = found.keys.where((f) => (hit[f] ?? 0) == 0).toList()
    ..sort((a, b) => found[b]!.compareTo(found[a]!));
  if (untouched.isNotEmpty) {
    stdout
      ..writeln('')
      ..writeln('Fichiers à 0 % les plus volumineux :');
    for (final file in untouched.take(10)) {
      stdout.writeln('  ${found[file].toString().padLeft(5)} lignes  $file');
    }
  }

  // L'exclusion reste visible : elle s'audite à chaque exécution.
  if (skippedFound.isNotEmpty) {
    stdout
      ..writeln('')
      ..writeln(
        'Hors périmètre ($skippedLines lignes) — non atteignable hors appareil :',
      );
    final skipped = skippedFound.keys.toList()
      ..sort((a, b) => skippedFound[b]!.compareTo(skippedFound[a]!));
    for (final file in skipped) {
      final label = file.replaceFirst('lib/', '');
      stdout.writeln(
        '  ${skippedFound[file].toString().padLeft(5)} lignes  '
        '${label.padRight(46)} ${_outOfScope[file]}',
      );
    }
  }
}
