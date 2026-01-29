import 'package:fpdart/fpdart.dart';
import 'package:mathani/core/errors/failures.dart';

abstract class MetadataRepository {
  Future<Either<Failure, Map<int, int>>> getSurahPageMap();
}
