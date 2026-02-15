import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:isar/isar.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/data/data_sources/local/quran_local_data_source.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/core/errors/failures.dart';
import 'package:mathani/core/utils/text_utils.dart';

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
      // AND NEW CHECK: Check if Ayahs have textClean populated (Migration)
      bool isDataValid = localSurahs.isNotEmpty && 
                         localSurahs.any((s) => s.page != null && s.page! > 0);

      if (isDataValid) {
        // Migration Check: Check first ayah of first surah
        final firstAyah = await _isar.ayahs.where().findFirst();
        if (firstAyah != null && (firstAyah.textClean.isEmpty)) {
           isDataValid = false; // Force reload to populate textClean
           debugPrint('Migration: triggering reload to populate textClean');
        }
      }

      if (isDataValid) {
        return Right(localSurahs);
      }
      
      // If data is invalid/stale, clear it before reloading
      if (localSurahs.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.surahs.clear();
          await _isar.ayahs.clear(); // Clear Ayahs too ensuring full reload
        });
      }
      
      // جلب من assets المحلية
      final surahs = await _localDataSource.loadAllSurahs();
      
      // حفظ السور في قاعدة البيانات
      await _isar.writeTxn(() async {
        await _isar.surahs.putAll(surahs);
      });

      // Also trigger loading of all Ayahs to populate the DB immediately 
      // (Optional but good for search availability)
      // For now, we rely on lazy loading or user opening Surahs, BUT for search to work globally, 
      // we really should have all Ayahs loaded.
      // Let's load them in background or just wait for user interaction?
      // Better: Load all Ayahs now if we are doing a full reset.
      _loadAllAyahsToDb(); 
      
      return Right(surahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _loadAllAyahsToDb() async {
    try {
       final allAyahs = await _localDataSource.loadAllAyahs();
       if (allAyahs.isNotEmpty) {
          await _isar.writeTxn(() async {
            await _isar.ayahs.putAll(allAyahs);
          });
       }
    } catch (e) {
      debugPrint('Error loading all ayahs: $e');
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async {
    try {
      // Normalize query
      final normalizedQuery = TextUtils.normalizeQuranText(query);
      
      if (kIsWeb) {
        // Web fallback
        return const Right([]); 
      }

      final results = await _isar.ayahs
          .filter()
          .textCleanContains(normalizedQuery, caseSensitive: false)
          .findAll();
          
      return Right(results);
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
  Future<Either<Failure, Ayah?>> getAyah(int surahNumber, int ayahNumber) async {
    try {
      if (kIsWeb) {
         // Not optimized for web single fetch yet, uses bulk load
        final ayahs = await _localDataSource.loadAyahsForSurah(surahNumber);
        try {
          final ayah = ayahs.firstWhere((a) => a.ayahNumber == ayahNumber);
          return Right(ayah);
        } catch (_) {
          return const Right(null);
        }
      }

      final ayah = await _isar.ayahs
          .filter()
          .surahNumberEqualTo(surahNumber)
          .and()
          .ayahNumberEqualTo(ayahNumber)
          .findFirst();
          
      return Right(ayah);
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

  @override
  Future<Either<Failure, List<Ayah>>> getAyahsCountRange(int startSurah, int startAyah, int endSurah, int endAyah) async {
    try {
      if (kIsWeb) {
        return const Right([]); 
      }

      // Simple Logic for Range:
      List<Ayah> results = [];
      
      // 1. Get Start Surah Ayahs
      final startAyahs = await _isar.ayahs
          .filter()
          .surahNumberEqualTo(startSurah)
          .ayahNumberGreaterThan(startAyah - 1)
          .findAll();
          
      results.addAll(startAyahs);

      // 2. Get In-Between Surahs (if any)
      if (endSurah > startSurah + 1) {
        final middle = await _isar.ayahs
            .filter()
            .surahNumberGreaterThan(startSurah)
            .and()
            .surahNumberLessThan(endSurah)
            .findAll();
        results.addAll(middle);
      }

      // 3. Get End Surah Ayahs (if different)
      if (endSurah > startSurah) {
        final endAyahs = await _isar.ayahs
            .filter()
            .surahNumberEqualTo(endSurah)
            .ayahNumberLessThan(endAyah + 1)
            .findAll();
        results.addAll(endAyahs);
      }
      
      // Filter out if startSurah == endSurah (we added too many in step 1, need to clip)
      if (startSurah == endSurah) {
        results = results.where((a) => a.ayahNumber <= endAyah).toList();
      }
      
      // Sort by Surah then Ayah
      results.sort((a, b) {
        if (a.surahNumber != b.surahNumber) return a.surahNumber.compareTo(b.surahNumber);
        return a.ayahNumber.compareTo(b.ayahNumber);
      });

      return Right(results);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}