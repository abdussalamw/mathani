import 'package:fpdart/fpdart.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/core/errors/failures.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getAllSurahs();
  Future<Either<Failure, Surah?>> getSurahByNumber(int number); // Added
  Future<Either<Failure, List<Ayah>>> getAyahsForSurah(int surahNumber);
  Future<Either<Failure, List<Ayah>>> getAyahsForPage(int pageNumber);
  Future<Either<Failure, List<Ayah>>> getAyahsCountRange(int startSurah, int startAyah, int endSurah, int endAyah); // Added for dynamic pages
  Future<Either<Failure, List<Ayah>>> getAllAyahs();
  Future<Either<Failure, Ayah?>> getAyah(int surahNumber, int ayahNumber); // Added for single ayah fetch
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query); // Added for search
  
  // Added methods for feature parity
  Future<Either<Failure, void>> updateLastRead(int surahNumber, int ayahNumber);
  Future<Either<Failure, void>> toggleFavorite(int surahNumber);
}
