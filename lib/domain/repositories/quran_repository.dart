import '../../core/database/collections.dart';

abstract class QuranRepository {
  Future<List<Surah>> getAllSurahs();
  Future<List<Ayah>> getAyahsForSurah(int surahNumber);
  Future<List<Ayah>> getAyahsForPage(int pageNumber);
  Future<List<Ayah>> getAllAyahs();
}
