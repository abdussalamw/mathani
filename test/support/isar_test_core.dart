import 'dart:io';
import 'dart:convert';
import 'dart:ffi';

import 'package:isar_community/isar.dart';

Future<void> initializeTestIsar() async {
  final configFile = File('.dart_tool/package_config.json').absolute;
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final package = packages.cast<Map<String, dynamic>>().singleWhere(
    (p) => p['name'] == 'isar_community_flutter_libs',
  );
  final rootUri = package['rootUri'] as String;
  final packageRoot = configFile.uri.resolve(
    rootUri.endsWith('/') ? rootUri : '$rootUri/',
  );
  final library = Platform.isWindows
      ? 'windows/libisar.dll'
      : Platform.isMacOS
      ? 'macos/libisar.dylib'
      : 'linux/libisar.so';
  await Isar.initializeIsarCore(
    libraries: {Abi.current(): packageRoot.resolve(library).toFilePath()},
  );
}
