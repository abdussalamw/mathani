import 'package:fpdart/fpdart.dart';

import '../../domain/repositories/metadata_repository.dart';
import 'package:mathani/core/errors/failures.dart';
import '../data_sources/local/metadata_local_data_source.dart';

class MetadataRepositoryImpl implements MetadataRepository {
  final MetadataLocalDataSource _dataSource = MetadataLocalDataSource();
  
  // Cache in memory
  Map<int, int>? _surahPageCache;

  @override
  Future<Either<Failure, Map<int, int>>> getSurahPageMap() async {
    if (_surahPageCache != null) return Right(_surahPageCache!);

    try {
      final jsonMap = await _dataSource.loadQuranMetadata();
      final rawMap = jsonMap['surah_to_page'] as Map<String, dynamic>;
      
      final Map<int, int> result = {};
      rawMap.forEach((key, value) {
        result[int.parse(key)] = value as int;
      });
      
      _surahPageCache = result;
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
