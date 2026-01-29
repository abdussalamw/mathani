import 'package:fpdart/fpdart.dart';
import '../entities/surah.dart';
import '../entities/ayah.dart';
import '../core/errors/failures.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getAllSurahs();
  Future<Either<Failure, List<Ayah>>> getAyahsForSurah(int surahNumber);
  Future<Either<Failure, List<Ayah>>> getAyahsForPage(int pageNumber);
  Future<Either<Failure, List<Ayah>>> getAllAyahs();
}
