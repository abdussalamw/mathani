import 'dart:io';

Future<void> main() async {
  final result = await Process.run(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['gen-l10n'],
    runInShell: Platform.isWindows,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    return;
  }

  // Flutter 3.50 still generates delegates from the bundled design libraries.
  final output = File('lib/l10n/app_localizations.dart');
  final source = await output.readAsString();
  const oldImport =
      "import 'package:flutter_localizations/flutter_localizations.dart';";
  const newImports =
      "import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;\n"
      "import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;\n"
      "import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;";
  if (!source.contains(oldImport)) {
    if (!source.contains("package:material_ui/material_ui.dart")) {
      throw StateError(
        'Unexpected localization imports; review the Flutter generator output.',
      );
    }
    return;
  }
  await output.writeAsString(source.replaceFirst(oldImport, newImports));
  final formatting = await Process.run(Platform.resolvedExecutable, [
    'format',
    output.path,
  ]);
  stdout.write(formatting.stdout);
  stderr.write(formatting.stderr);
  exitCode = formatting.exitCode;
}
