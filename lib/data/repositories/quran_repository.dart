import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:fpdart/fpdart.dart';

import '../data_sources/remote/quran_remote_data_source.dart';
import '../../core/database/collections.dart' as model;
import '../../core/database/isar_service.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/entities/surah.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/core/errors/failures.dart';
import '../mappers/surah_mapper.dart';
import '../mappers/ayah_mapper.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranRemoteDataSource _remoteDataSource = QuranRemoteDataSource();

  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    try {
      final isar = await IsarService.instance.db;
      
      // 1. Check local DB
      final count = await isar.surahs.count();
      if (count > 0) {
        final localSurahs = await isar.surahs.where().sortByNumber().findAll();
        return Right(SurahMapper.toEntityList(localSurahs));
      }

      // 2. Fetch from API
      debugPrint('Fetching Surahs from API...');
      final surahsMap = await _remoteDataSource.fetchAllSurahs();
      final surahsList = surahsMap['data'] as List;

      final List<model.Surah> newSurahs = [];
      
      for (var s in surahsList) {
        final surahModel = model.Surah()
          ..number = s['number']
          ..nameArabic = s['name']
          ..nameEnglish = s['englishName']
          ..revelation = s['revelationType'] == 'Meccan' 
              ? model.RevelationType.meccan 
              : model.RevelationType.medinan
          ..numberOfAyahs = s['numberOfAyahs']
          ..juzNumber = 1 
          ..page = 1; 
          
        newSurahs.add(surahModel);
      }

      await isar.writeTxn(() async {
        await isar.surahs.putAll(newSurahs);
      });

      // 4. Fetch Ayahs lazily/background (catching error separately to not fail surah list)
      _fetchAndSaveAyahs(isar).catchError((e) => debugPrint('Ayah sync error: $e'));

      return Right(SurahMapper.toEntityList(newSurahs));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _fetchAndSaveAyahs(Isar isar) async {
      debugPrint('Fetching Full Quran Text...');
      final quranMap = await _remoteDataSource.fetchFullQuran();
      final surahsData = quranMap['data']['surahs'] as List;

      final List<model.Ayah> allAyahs = [];

      for (var sData in surahsData) {
        final int surahNum = sData['number'];
        final ayahsList = sData['ayahs'] as List;

        for (var aData in ayahsList) {
          final ayah = model.Ayah()
            ..surahNumber = surahNum
            ..ayahNumber = aData['numberInSurah']
            ..textUthmani = aData['text']
            ..textSimple = aData['text']
            ..page = aData['page']
            ..juz = aData['juz']
            ..hizbQuarter = aData['hizbQuarter'];
          
          allAyahs.add(ayah);
        }
      }

      await isar.writeTxn(() async {
        await isar.ayahs.putAll(allAyahs);
      });
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAyahsForSurah(int surahNumber) async {
    try {
      final isar = await IsarService.instance.db;
      final ayahs = await isar.ayahs
          .filter()
          .surahNumberEqualTo(surahNumber)
          .sortByAyahNumber()
          .findAll();
      return Right(AyahMapper.toEntityList(ayahs));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Ayah>>> getAyahsForPage(int pageNumber) async {
    try {
      final isar = await IsarService.instance.db;
      final ayahs = await isar.ayahs
          .filter()
          .pageEqualTo(pageNumber)
          .sortBySurahNumber()
          .thenByAyahNumber()
          .findAll();
      return Right(AyahMapper.toEntityList(ayahs));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAllAyahs() async {
    try {
      final isar = await IsarService.instance.db;
      final ayahs = await isar.ayahs
          .where()
          .sortBySurahNumber()
          .thenByAyahNumber()
          .findAll();
      return Right(AyahMapper.toEntityList(ayahs));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
