
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../core/data/remote_data_source.dart';
import '../core/database/collections.dart';
import '../core/database/isar_service.dart';

class QuranRepository {
  final RemoteDataSource _remoteDataSource = RemoteDataSource();

  // Get all Surahs (from DB or API)
  Future<List<Surah>> getAllSurahs() async {
    final isar = await IsarService.instance.db;
    
    // 1. Check if data exists in Isar
    final count = await isar.surahs.count();
    if (count > 0) {
      return await isar.surahs.where().sortByNumber().findAll();
    }

    // 2. If not, fetch from API
    try {
      debugPrint('Fetching Surahs from API...');
      final surahsMap = await _remoteDataSource.fetchAllSurahs();
      final surahsList = surahsMap['data'] as List;

      // 3. Convert and Save Surahs
      final List<Surah> newSurahs = [];
      
      for (var s in surahsList) {
        final surah = Surah()
          ..number = s['number']
          ..nameArabic = s['name']
          ..nameEnglish = s['englishName']
          ..revelation = s['revelationType'] == 'Meccan' 
              ? RevelationType.meccan 
              : RevelationType.medinan
          ..numberOfAyahs = s['numberOfAyahs']
          // Note: API might not give start page/juz directly in this endpoint easily for all, 
          // but let's assume valid data or default to 1 for now.
          // Ideally we get this from detailed meta or calculate it.
          // For this MVP step, we will rely on the list data.
          ..juzNumber = 1 // Placeholder, will update with Ayah data logic if needed
          ..page = 1;     // Placeholder
          
        newSurahs.add(surah);
      }

      await isar.writeTxn(() async {
        await isar.surahs.putAll(newSurahs);
      });

      // 4. Also fetch full Quran Text for Ayahs if needed immediately, 
      // or we can do it lazily. for offline-first, let's try to fetch text too.
      // Launching it in background or awaiting it? Let's await for robustness.
      await _fetchAndSaveAyahs(isar);

      return newSurahs;
    } catch (e) {
      debugPrint('Error in QuranRepository: $e');
      rethrow;
    }
  }
  
  // Fetch and Save Ayahs
  Future<void> _fetchAndSaveAyahs(Isar isar) async {
    try {
      debugPrint('Fetching Full Quran Text...');
      final quranMap = await _remoteDataSource.fetchFullQuran();
      final surahsData = quranMap['data']['surahs'] as List;

      final List<Ayah> allAyahs = [];

      for (var sData in surahsData) {
        final int surahNum = sData['number'];
        final ayahsList = sData['ayahs'] as List;

        for (var aData in ayahsList) {
          final ayah = Ayah()
            ..surahNumber = surahNum
            ..ayahNumber = aData['numberInSurah']
            ..textUthmani = aData['text']
            ..textSimple = aData['text'] // Simple text might need another source or stripping diacritics
            ..page = aData['page']
            ..juz = aData['juz']
            ..hizbQuarter = aData['hizbQuarter'];
          
          allAyahs.add(ayah);
        }
      }

      await isar.writeTxn(() async {
        // Use importing logic or batch to speed up
        // Isar is fast, 6236 items is fine.
        await isar.ayahs.putAll(allAyahs);
      });
      
      debugPrint('Ayahs saved successfully: ${allAyahs.length}');

    } catch (e) {
      debugPrint('Error saving ayahs: $e');
      // Non-blocking error for Surah list, but critical for reading
      throw e; 
    }
  }

  // Get Ayahs for a specific Surah
  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final isar = await IsarService.instance.db;
    return await isar.ayahs
        .filter()
        .surahNumberEqualTo(surahNumber)
        .sortByAyahNumber()
        .findAll();
  }
  
  // Get Pages (for Mushaf View)
  Future<List<Ayah>> getAyahsForPage(int pageNumber) async {
    final isar = await IsarService.instance.db;
    return await isar.ayahs
        .filter()
        .pageEqualTo(pageNumber)
        .sortBySurahNumber()
        .thenByAyahNumber()
        .findAll();
  }
}
