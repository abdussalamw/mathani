import 'package:fpdart/fpdart.dart';
import '../repositories/quran_repository.dart';
import '../entities/surah.dart';
import '../core/errors/failures.dart';

class GetAllSurahsUseCase {
  final QuranRepository repository;
  GetAllSurahsUseCase(this.repository);

  Future<Either<Failure, List<Surah>>> call() {
    return repository.getAllSurahs();
  }
}
