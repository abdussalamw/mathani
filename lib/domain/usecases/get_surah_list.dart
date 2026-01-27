import '../../core/database/collections.dart';
import '../../data/repositories/quran_repository.dart';

class GetSurahListUseCase {
  final QuranRepository repository;

  GetSurahListUseCase(this.repository);

  Future<List<Surah>> call() async {
    return await repository.getAllSurahs();
  }
}
