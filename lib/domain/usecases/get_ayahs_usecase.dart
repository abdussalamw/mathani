import 'package:fpdart/fpdart.dart';
import '../repositories/quran_repository.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/core/errors/failures.dart';

class GetAyahsForSurahUseCase {
  final QuranRepository repository;
  GetAyahsForSurahUseCase(this.repository);

  Future<Either<Failure, List<Ayah>>> call(int surahNumber) {
    return repository.getAyahsForSurah(surahNumber);
  }
}

class GetAyahsForPageUseCase {
  final QuranRepository repository;
  GetAyahsForPageUseCase(this.repository);

  Future<Either<Failure, List<Ayah>>> call(int pageNumber) {
    return repository.getAyahsForPage(pageNumber);
  }
}

class GetAllAyahsUseCase {
  final QuranRepository repository;
  GetAllAyahsUseCase(this.repository);

  Future<Either<Failure, List<Ayah>>> call() {
    return repository.getAllAyahs();
  }
}
