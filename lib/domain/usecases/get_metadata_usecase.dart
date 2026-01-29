import 'package:fpdart/fpdart.dart';
import '../repositories/metadata_repository.dart';
import 'package:mathani/core/errors/failures.dart';

class GetSurahPageMapUseCase {
  final MetadataRepository repository;
  GetSurahPageMapUseCase(this.repository);

  Future<Either<Failure, Map<int, int>>> call() {
    return repository.getSurahPageMap();
  }
}
