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
  final Isar _isar;
  
  QuranRepositoryImpl({
    QuranLocalDataSource? localDataSource,
    Isar? isar,
  })  : _localDataSource = localDataSource ?? QuranLocalDataSource.instance,
        _isar = isar ?? IsarService.instance.isar;
  
  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    try {
      // تحقق من قاعدة البيانات أولاً
      final localSurahs = await _isar.surahs.where().findAll();
      
      if (localSurahs.isNotEmpty) {
        return Right(localSurahs);
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
    // Not implemented yet
    return const Right([]);
  }
}