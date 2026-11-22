import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mathani/data/data_sources/local/quran_local_data_source.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/repositories/quran_repository.dart';

import '../../support/isar_test_core.dart';

class _Source implements QuranLocalDataSource {
  int loads = 0;
  @override
  Future<List<Surah>> loadAllSurahs() async => [
    Surah()
      ..number = 2
      ..page = 2,
  ];
  @override
  Future<List<Ayah>> loadAllAyahs() async {
    loads++;
    return [
      for (var i = 1; i <= 3; i++)
        Ayah.fromJson({'id': i, 'text': 'نص', 'page': 2}, 2),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(initializeTestIsar);
  test(
    'repairs partial and duplicate rows in place and shares concurrent work',
    () async {
      final dir = await Directory.systemTemp.createTemp('mathani_repo_');
      final db = await Isar.open([
        SurahSchema,
        AyahSchema,
      ], directory: dir.path);
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final old = Ayah()
        ..surahNumber = 2
        ..ayahNumber = 3
        ..notes = 'ملاحظة'
        ..isBookmarked = true;
      final duplicate = Ayah()
        ..surahNumber = 2
        ..ayahNumber = 3
        ..isFavorite = true;
      await db.writeTxn(() async {
        await db.ayahs.putAll([old, duplicate]);
        await db.surahs.put(
          Surah()
            ..number = 2
            ..isFavorite = true
            ..lastReadAyah = 3,
        );
      });
      final source = _Source();
      final repo = QuranRepositoryImpl(isar: db, localDataSource: source);
      final surahs = repo.getAllSurahs();
      final page = repo.getAyahsForPage(2);
      final matches = await repo.searchAyahs('نص');
      expect(matches.getOrElse((_) => []).length, 3);
      expect((await page).getOrElse((_) => []).map((a) => a.ayahNumber), [
        1,
        2,
        3,
      ]);
      final saved = (await surahs).getOrElse((_) => []).single;
      expect(saved.isFavorite, isTrue);
      expect(saved.lastReadAyah, 3);
      expect(source.loads, 1);
      expect(await db.ayahs.count(), 4);
      final repaired = await db.ayahs.get(old.id);
      expect(repaired!.notes, 'ملاحظة');
      expect(repaired.isBookmarked, isTrue);
      expect(repaired.textClean, 'نص');
      expect((await db.ayahs.get(duplicate.id))!.isFavorite, isTrue);
    },
  );
}
