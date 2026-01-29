import 'package:fpdart/fpdart.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/core/errors/failures.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getAllSurahs();
  Future<Either<Failure, Surah?>> getSurahByNumber(int number); // Added
  Future<Either<Failure, List<Ayah>>> getAyahsForSurah(int surahNumber);
  Future<Either<Failure, List<Ayah>>> getAyahsForPage(int pageNumber);
  Future<Either<Failure, List<Ayah>>> getAllAyahs();
  
  // Added methods for feature parity
  Future<Either<Failure, void>> updateLastRead(int surahNumber, int ayahNumber);
  Future<Either<Failure, void>> toggleFavorite(int surahNumber);
}
