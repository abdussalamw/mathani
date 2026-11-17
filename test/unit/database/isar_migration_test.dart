import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/data/models/recitation_session.dart';

void main() {
  late Directory temporaryDirectory;
  final service = IsarService.instance;

  setUpAll(() async {
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
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'mathani_isar_test_',
    );
  });

  tearDown(() async {
    await service.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'collection identities, properties and indexes match Isar 3.1.0+1',
    () async {
      final legacyIds = jsonDecode(
        await File('test/fixtures/isar_v3/collection_ids.json').readAsString(),
      );
      expect({
        for (final schema in IsarService.schemas) schema.name: schema.id,
      }, legacyIds);
      final legacySchema = jsonDecode(
        await File('test/fixtures/isar_v3/schema.json').readAsString(),
      );
      final currentSchema = IsarService.schemas
          .map(
            (schema) => {
              'name': schema.name,
              'embedded': schema.embedded,
              'properties': schema.properties.values
                  .map(
                    (property) => {
                      'name': property.name,
                      'type': property.type.schemaName,
                    },
                  )
                  .toList(),
              'idName': schema.idName,
              'indexes': schema.indexes.values
                  .map(
                    (index) => {
                      'name': index.name,
                      'unique': index.unique,
                      'replace': index.replace,
                      'properties': index.properties
                          .map(
                            (property) => {
                              'name': property.name,
                              'type': {
                                IndexType.value: 'Value',
                                IndexType.hash: 'Hash',
                                IndexType.hashElements: 'HashElements',
                              }[property.type],
                              'caseSensitive': property.caseSensitive,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
              'links': schema.links.values.toList(),
              'embeddedSchemas': schema.embeddedSchemas.values.toList(),
            },
          )
          .toList();
      expect(currentSchema, legacySchema);
    },
  );

  test(
    'reads every legacy collection, preserves a backup, and persists updates',
    () async {
      final fixture = File('test/fixtures/isar_v3/default.isar');
      final originalBytes = await fixture.readAsBytes();
      await fixture.copy('${temporaryDirectory.path}/default.isar');
      await service.init(directory: temporaryDirectory.path);

      final db = service.isar;
      final expected = jsonDecode(
        await File('test/fixtures/isar_v3/expected.json').readAsString(),
      );
      final actual = {
        'Surah': await db.collection<Surah>().where().exportJson(),
        'Ayah': await db.collection<Ayah>().where().exportJson(),
        'UserSettings': await db
            .collection<UserSettings>()
            .where()
            .exportJson(),
        'MushafMetadata': await db
            .collection<MushafMetadata>()
            .where()
            .exportJson(),
        'AudioCache': await db.collection<AudioCache>().where().exportJson(),
        'ReadingProgress': await db
            .collection<ReadingProgress>()
            .where()
            .exportJson(),
        'Bookmark': await db.collection<Bookmark>().where().exportJson(),
        'Tafsir': await db.collection<Tafsir>().where().exportJson(),
        'RecitationSession': await db
            .collection<RecitationSession>()
            .where()
            .exportJson(),
      };
      expect(actual, expected);
      final backup = File(
        '${temporaryDirectory.path}/default.isar.before-community-3.4.1',
      );
      expect(await backup.readAsBytes(), originalBytes);
      expect(
        (await db.surahs.where().numberEqualTo(1).findFirst())?.nameArabic,
        'الفاتحة',
      );
      expect(
        (await db.ayahs.where().surahNumberAyahNumberEqualTo(1, 1).findFirst())
            ?.notes,
        'ملاحظة محفوظة',
      );

      final bookmark = (await db.collection<Bookmark>().get(1))!;
      bookmark.note = 'تمت المراجعة';
      await db.writeTxn(() => db.collection<Bookmark>().put(bookmark));
      await service.close();
      expect(() => service.isar, throwsStateError);
      await service.init(directory: temporaryDirectory.path);
      expect(
        (await service.isar.collection<Bookmark>().get(1))?.note,
        'تمت المراجعة',
      );
      expect(await backup.readAsBytes(), originalBytes);
      expect(await fixture.readAsBytes(), originalBytes);
    },
  );

  test(
    'failed opening preserves the original file and reports the error',
    () async {
      final databaseFile = File('${temporaryDirectory.path}/default.isar');
      final corruptBytes = List<int>.generate(65536, (i) => i % 256);
      await databaseFile.writeAsBytes(corruptBytes);
      await expectLater(
        service.init(directory: temporaryDirectory.path),
        throwsA(isA<IsarError>()),
      );
      expect(await databaseFile.readAsBytes(), corruptBytes);
      expect(
        await File('${databaseFile.path}.before-community-3.4.1').readAsBytes(),
        corruptBytes,
      );
      expect(() => service.isar, throwsStateError);
    },
  );
}
