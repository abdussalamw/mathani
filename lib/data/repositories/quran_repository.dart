import 'package:isar/isar.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/core/network/api_client.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';

class QuranRepository {
  final ApiClient _apiClient;
  final Isar _isar;
  
  QuranRepository({
    ApiClient? apiClient,
    Isar? isar,
  })  : _apiClient = apiClient ?? ApiClient(),
        _isar = isar ?? IsarService.instance.isar;
  
  // جلب جميع السور (من DB أو API)
  Future<List<Surah>> getAllSurahs() async {
    // تحقق من قاعدة البيانات أولاً
    final localSurahs = await _isar.surahs.where().findAll();
    
    if (localSurahs.isNotEmpty) {
      return localSurahs;
    }
    
    // إن لم تكن موجودة، جلب من API
    final surahsData = await _apiClient.fetchAllSurahs();
    final surahs = surahsData.map((json) => Surah.fromJson(json)).toList();
    
    // حفظ في قاعدة البيانات
    await _isar.writeTxn(() async {
      await _isar.surahs.putAll(surahs);
    });
    
    return surahs;
  }
  
  // جلب سورة معينة
  Future<Surah?> getSurahByNumber(int number) async {
    return await _isar.surahs
        .filter()
        .numberEqualTo(number)
        .findFirst();
  }
  
  // جلب آيات سورة معينة
  Future<List<Ayah>> getAyahsOfSurah(int surahNumber) async {
    // تحقق من قاعدة البيانات
    final localAyahs = await _isar.ayahs
        .filter()
        .surahNumberEqualTo(surahNumber)
        .findAll();
    
    if (localAyahs.isNotEmpty) {
      return localAyahs;
    }
    
    // جلب من API
    final surahData = await _apiClient.fetchSurah(surahNumber);
    final ayahsJson = surahData['ayahs'] as List;
    
    final ayahs = ayahsJson
        .map((json) => Ayah.fromJson(json, surahNumber))
        .toList();
    
    // حفظ في قاعدة البيانات
    await _isar.writeTxn(() async {
      await _isar.ayahs.putAll(ayahs);
    });
    
    return ayahs;
  }
  
  // تحديث آخر قراءة
  Future<void> updateLastRead(int surahNumber, int ayahNumber) async {
    final surah = await getSurahByNumber(surahNumber);
    
    if (surah != null) {
      surah.lastReadAyah = ayahNumber;
      surah.lastReadTime = DateTime.now();
      
      await _isar.writeTxn(() async {
        await _isar.surahs.put(surah);
      });
    }
  }
  
  // إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(int surahNumber) async {
    final surah = await getSurahByNumber(surahNumber);
    
    if (surah != null) {
      surah.isFavorite = !surah.isFavorite;
      
      await _isar.writeTxn(() async {
        await _isar.surahs.put(surah);
      });
    }
  }
}