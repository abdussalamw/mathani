import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:isar_community/isar.dart';
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

  Future<void>? _loadingAyahsFuture;

  QuranRepositoryImpl({QuranLocalDataSource? localDataSource, Isar? isar})
    : _localDataSource = localDataSource ?? QuranLocalDataSource.instance,
      _injectedIsar = isar;

  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    try {
      if (kIsWeb) {
        // On Web, skip DB and load directly from assets
        final surahs = await _localDataSource.loadAllSurahs();
        return Right(surahs);
      }

      final local = await _isar.surahs.where().findAll();
      if (local.length != 114 || local.any((s) => (s.page ?? 0) < 1)) {
        final fresh = await _localDataSource.loadAllSurahs();
        await _isar.writeTxn(() async {
          final existing = {
            for (final s in await _isar.surahs.where().findAll()) s.number: s,
          };
          for (final surah in fresh) {
            final stored = existing[surah.number];
            if (stored != null) {
              surah.id = stored.id;
              surah.isFavorite = stored.isFavorite;
              surah.lastReadTime = stored.lastReadTime;
              surah.lastReadAyah = stored.lastReadAyah;
            }
          }
          await _isar.surahs.putAll(fresh);
        });
      }
      await _ensureAyahs();
      return Right(await _isar.surahs.where().sortByNumber().findAll());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  bool _ayahsReady = false;
  Future<void> _ensureAyahs() async {
    if (_ayahsReady) return;
    final pending = _loadingAyahsFuture ??= _mergeAyahs();
    try {
      await pending;
      _ayahsReady = true;
    } finally {
      if (identical(_loadingAyahsFuture, pending)) _loadingAyahsFuture = null;
    }
  }

  Future<void> _mergeAyahs() async {
    final source = await _localDataSource.loadAllAyahs();
    if (source.isEmpty) throw StateError('بيانات الآيات غير متاحة');
    await _isar.writeTxn(() async {
      final rows = await _isar.ayahs.where().findAll();
      final stored = <(int, int), List<Ayah>>{};
      for (final row in rows) {
        stored
            .putIfAbsent((row.surahNumber, row.ayahNumber), () => [])
            .add(row);
      }
      final updates = <Ayah>[];
      for (final canonical in source) {
        final matches = stored[(canonical.surahNumber, canonical.ayahNumber)];
        if (matches == null) {
          updates.add(canonical);
          continue;
        }
        for (final row in matches) {
          if (row.text != canonical.text ||
              row.textClean != canonical.textClean ||
              row.juz != canonical.juz ||
              row.page != canonical.page) {
            row.text = canonical.text;
            row.textClean = canonical.textClean;
            row.juz = canonical.juz;
            row.page = canonical.page;
            updates.add(row);
          }
        }
      }
      if (updates.isNotEmpty) await _isar.ayahs.putAll(updates);
    });
  }

  List<Ayah> _uniqueAyahs(List<Ayah> rows) {
    final keys = <(int, int)>{};
    return rows.where((a) => keys.add((a.surahNumber, a.ayahNumber))).toList();
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

      await _ensureAyahs();
      final results = await _isar.ayahs
          .filter()
          .textCleanContains(normalizedQuery, caseSensitive: false)
          .findAll();

      return Right(_uniqueAyahs(results));
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
  Future<Either<Failure, Ayah?>> getAyah(
    int surahNumber,
    int ayahNumber,
  ) async {
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

      await _ensureAyahs();
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

      await _ensureAyahs();
      final rows = await _isar.ayahs
          .filter()
          .surahNumberEqualTo(surahNumber)
          .sortByAyahNumber()
          .findAll();
      return Right(_uniqueAyahs(rows));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastRead(
    int surahNumber,
    int ayahNumber,
  ) async {
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
        return const Left(CacheFailure('Surah not found'));
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
        return const Left(CacheFailure('Surah not found'));
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
      await _ensureAyahs();
      final localAyahs = await _isar.ayahs
          .filter()
          .pageEqualTo(pageNumber)
          .sortBySurahNumber()
          .thenByAyahNumber()
          .findAll();

      if (localAyahs.isNotEmpty) {
        return Right(_uniqueAyahs(localAyahs));
      }

      // Fallback
      final ayahs = await _localDataSource.loadAyahsForPage(pageNumber);
      return Right(ayahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ayah>>> getAyahsCountRange(
    int startSurah,
    int startAyah,
    int endSurah,
    int endAyah,
  ) async {
    try {
      if (kIsWeb) {
        return const Right([]);
      }

      // Simple Logic for Range:
      List<Ayah> results = [];

      // 1. Get Start Surah Ayahs
      await _ensureAyahs();
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
        if (a.surahNumber != b.surahNumber) {
          return a.surahNumber.compareTo(b.surahNumber);
        }
        return a.ayahNumber.compareTo(b.ayahNumber);
      });

      return Right(_uniqueAyahs(results));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
