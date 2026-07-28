// Génère `test/all_imports_test.dart`.
//
// Pourquoi : la couverture Dart n'instrumente **que les fichiers importés par un
// test**. Un fichier que personne n'importe n'est pas compté « 0 % » — il est
// purement **absent** du rapport, ce qui gonfle artificiellement le pourcentage.
// Ce générateur importe chaque fichier de `lib/` pour rendre la mesure honnête.
//
// Usage : dart run tool/gen_coverage_imports.dart
library;

import 'dart:io';

const _output = 'test/all_imports_test.dart';
const _package = 'realmguard';

/// Fichiers exclus de la mesure : code **généré** (drift `*.g.dart`, bindings
/// FFI `lib/src/rust/`). Les inclure écraserait le score sans rien apprendre.
bool _isMeasurable(String path) =>
    path.endsWith('.dart') &&
    !path.endsWith('.g.dart') &&
    !path.contains('/src/rust/');

List<String> collectLibFiles() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(Platform.pathSeparator, '/'))
      .where(_isMeasurable)
      .toList();
  files.sort();
  return files;
}

void main() {
  final files = collectLibFiles();
  final buffer = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/gen_coverage_imports.dart — ne pas éditer.')
    ..writeln('//')
    ..writeln(
      '// Importe tous les fichiers de `lib/` pour qu ils apparaissent dans le',
    )
    ..writeln(
      '// rapport de couverture (Dart n instrumente que ce qui est importé), et',
    )
    ..writeln('// vérifie que cette liste reste synchronisée avec le disque.')
    ..writeln('//')
    ..writeln('// ignore_for_file: unused_import, directives_ordering')
    ..writeln("library;")
    ..writeln()
    ..writeln("import 'dart:io';")
    ..writeln()
    ..writeln("import 'package:flutter_test/flutter_test.dart';");

  // Imports **aliasés** : sans alias, `main.dart` (et tout symbole homonyme)
  // entrerait en collision avec le `main()` du test.
  for (var i = 0; i < files.length; i++) {
    final relative = files[i].substring('lib/'.length);
    buffer.writeln("import 'package:$_package/$relative' as i$i;");
  }

  buffer
    ..writeln()
    ..writeln('/// Liste figée au moment de la génération.')
    ..writeln('const _generated = <String>[');
  for (final file in files) {
    buffer.writeln("  '$file',");
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('bool _isMeasurable(String path) =>')
    ..writeln("    path.endsWith('.dart') &&")
    ..writeln("    !path.endsWith('.g.dart') &&")
    ..writeln("    !path.contains('/src/rust/');")
    ..writeln()
    ..writeln('void main() {')
    ..writeln('  test(')
    ..writeln(
      "    'garde-fou couverture : les imports générés couvrent tout lib/',",
    )
    ..writeln('    () {')
    ..writeln("      final onDisk = Directory('lib')")
    ..writeln('          .listSync(recursive: true)')
    ..writeln('          .whereType<File>()')
    ..writeln(
      '          .map((file) => file.path.replaceAll(Platform.pathSeparator, '
      "'/'))",
    )
    ..writeln('          .where(_isMeasurable)')
    ..writeln('          .toList()')
    ..writeln('        ..sort();')
    ..writeln('      expect(')
    ..writeln('        onDisk,')
    ..writeln('        _generated,')
    ..writeln('        reason:')
    ..writeln(
      "            'lib/ a changé : relance "
      "`dart run tool/gen_coverage_imports.dart`',",
    )
    ..writeln('      );')
    ..writeln('    },')
    ..writeln('  );')
    ..writeln('}');

  File(_output).writeAsStringSync(buffer.toString());
  stdout.writeln('$_output généré — ${files.length} fichiers importés.');
}
