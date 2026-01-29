import 'package:fpdart/fpdart.dart';
import '../repositories/quran_repository.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/core/errors/failures.dart';

class GetAllSurahsUseCase {
  final QuranRepository repository;
  GetAllSurahsUseCase(this.repository);

  Future<Either<Failure, List<Surah>>> call() {
    return repository.getAllSurahs();
  }
}
