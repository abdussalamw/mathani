import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:isar/isar.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/data/data_sources/local/quran_local_data_source.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/core/errors/failures.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource _localDataSource;
  final Isar? _injectedIsar;
  
  // Lazy getter allows delay of access until initialization is complete
  Isar get _isar => _injectedIsar ?? IsarService.instance.isar;
  
  QuranRepositoryImpl({
    QuranLocalDataSource? localDataSource,
    Isar? isar,
  })  : _localDataSource = localDataSource ?? QuranLocalDataSource.instance,
        _injectedIsar = isar;
  
  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    try {
      if (kIsWeb) {
         // On Web, skip DB and load directly from assets
         final surahs = await _localDataSource.loadAllSurahs();
         return Right(surahs);
      }

      // تحقق من قاعدة البيانات أولاً
      final localSurahs = await _isar.surahs.where().findAll();
      
      // Check if we have data AND if the data is valid (has page numbers populated)
      // If page is null or 0, it means we have old data that needs to be refreshed
      bool isDataValid = localSurahs.isNotEmpty && 
                         localSurahs.any((s) => s.page != null && s.page! > 0);

      if (isDataValid) {
        return Right(localSurahs);
      }
      
      // If data is invalid/stale, clear it before reloading
      if (localSurahs.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.surahs.clear();
        });
      }
      
      // جلب من assets المحلية
      final surahs = await _localDataSource.loadAllSurahs();
      
      // حفظ في قاعدة البيانات
      await _isar.writeTxn(() async {
        await _isar.surahs.putAll(surahs);
      });
      
      return Right(surahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Surah?>> getSurahByNumber(int number) async {
    try {
      if (kIsWeb) {
        final all = await _localDataSource.loadAllSurahs();
        try {
          final surah = all.firstWhere((s) => s.number == number);
          return Right(surah);
        } catch (_) {
          return const Right(null);
        }
      }

      final surah = await _isar.surahs
          .filter()
          .numberEqualTo(number)
          .findFirst();
      return Right(surah);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Ayah>>> getAyahsForSurah(int surahNumber) async {
    try {
      if (kIsWeb) {
        final ayahs = await _localDataSource.loadAyahsForSurah(surahNumber);
        return Right(ayahs);
      }

      // تحقق من قاعدة البيانات
      final localAyahs = await _isar.ayahs
          .filter()
          .surahNumberEqualTo(surahNumber)
          .findAll();
      
      if (localAyahs.isNotEmpty) {
        return Right(localAyahs);
      }
      
      // جلب من assets المحلية
      final ayahs = await _localDataSource.loadAyahsForSurah(surahNumber);
      
      // حفظ في قاعدة البيانات
      await _isar.writeTxn(() async {
        await _isar.ayahs.putAll(ayahs);
      });
      
      return Right(ayahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> updateLastRead(int surahNumber, int ayahNumber) async {
    try {
      if (kIsWeb) return const Right(null); // No persistence on web for now

      final surah = await _isar.surahs
          .filter()
          .numberEqualTo(surahNumber)
          .findFirst();
      
      if (surah != null) {
        surah.lastReadAyah = ayahNumber;
        surah.lastReadTime = DateTime.now();
        
        await _isar.writeTxn(() async {
          await _isar.surahs.put(surah);
        });
        return const Right(null);
      } else {
        return Left(CacheFailure('Surah not found'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> toggleFavorite(int surahNumber) async {
    try {
      if (kIsWeb) return const Right(null); // No persistence on web for now

      final surah = await _isar.surahs
          .filter()
          .numberEqualTo(surahNumber)
          .findFirst();
      
      if (surah != null) {
        surah.isFavorite = !surah.isFavorite;
        
        await _isar.writeTxn(() async {
          await _isar.surahs.put(surah);
        });
        return const Right(null);
      } else {
         return Left(CacheFailure('Surah not found'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAllAyahs() async {
    // Not implemented yet
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAyahsForPage(int pageNumber) async {
    try {
      if (kIsWeb) {
        final ayahs = await _localDataSource.loadAyahsForPage(pageNumber);
        return Right(ayahs);
      }

      // Check Database first
      final localAyahs = await _isar.ayahs
          .filter()
          .pageEqualTo(pageNumber)
          .findAll();
      
      if (localAyahs.isNotEmpty) {
        return Right(localAyahs);
      }
      
      // Fallback
      final ayahs = await _localDataSource.loadAyahsForPage(pageNumber);
      return Right(ayahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}