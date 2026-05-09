import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/surah.dart';
import '../../models/ayah.dart';

class QuranLocalDataSource {
  static final QuranLocalDataSource _instance = QuranLocalDataSource._internal();
  static QuranLocalDataSource get instance => _instance;
  
  QuranLocalDataSource._internal();
  
  // Cache للبيانات المحملة
  List<dynamic>? _cachedData;
  
  /// تحميل البيانات من assets
  Future<List<dynamic>> _loadData() async {
    if (_cachedData != null) return _cachedData!;
    
    // استخدام الملف المتقدم المدمج (نص + صفحات)
    final jsonString = await rootBundle.loadString('assets/data/quran_advanced.json');
    _cachedData = json.decode(jsonString) as List<dynamic>;
    return _cachedData!;
  }
  
  /// جلب جميع السور
  Future<List<Surah>> loadAllSurahs() async {
    final data = await _loadData();
    final List<Surah> surahs = [];
    
    for (var item in data) {
      if (item is! Map<String, dynamic>) continue;
      
      int startPage = 1;
      if (item['verses'] != null && (item['verses'] is List) && (item['verses'] as List).isNotEmpty) {
        startPage = item['verses'][0]['page'] ?? 1;
      }

      surahs.add(Surah()
        ..number = item['id'] as int
        ..nameArabic = item['name'] as String
        ..nameEnglish = item['transliteration'] as String
        ..nameEnglishTranslation = item['transliteration'] as String // fallback
        ..numberOfAyahs = item['total_verses'] as int
        ..revelationType = item['type'] as String
        ..page = startPage
      );
    }
    
    return surahs;
  }
  
  /// جلب آيات سورة معينة
  Future<List<Ayah>> loadAyahsForSurah(int surahNumber) async {
    final data = await _loadData();
    final List<Ayah> ayahs = [];
    
    // البحث عن السورة المطلوبة
    final surahData = data.firstWhere(
      (item) => item['id'] == surahNumber,
      orElse: () => null,
    );
    
    if (surahData != null && surahData['verses'] is List) {
      final verses = surahData['verses'] as List;
      
      for (var verse in verses) {
        if (verse is! Map<String, dynamic>) continue;
         
        ayahs.add(Ayah()
          ..surahNumber = surahNumber
          ..ayahNumber = verse['id'] as int
          ..text = verse['text'] as String
          ..juz = verse['juz'] as int     // متوفر الآن
          ..page = verse['page'] as int   // متوفر الآن
        );
      }
    }
    
    return ayahs;
  }
  
  /// جلب آيات صفحة معينة
  Future<List<Ayah>> loadAyahsForPage(int pageNumber) async {
    final data = await _loadData();
    final List<Ayah> pageAyahs = [];
    
    for (var surahItem in data) {
      if (surahItem['verses'] is List) {
        final verses = surahItem['verses'] as List;
        for (var verse in verses) {
          if (verse['page'] == pageNumber) {
            pageAyahs.add(Ayah()
              ..surahNumber = surahItem['id'] as int
              ..ayahNumber = verse['id'] as int
              ..text = verse['text'] as String
              ..juz = verse['juz'] as int
              ..page = verse['page'] as int
            );
          }
        }
      }
    }
    
    // Sort by Surah then Ayah to be safe?
    // Usually they are in order.
    return pageAyahs;
  }

  /// جلب جميع الآيات (للبحث والتهيئة)
  Future<List<Ayah>> loadAllAyahs() async {
    final data = await _loadData();
    final List<Ayah> allAyahs = [];
    
    for (var surahItem in data) {
      if (surahItem is! Map<String, dynamic>) continue;
      final surahId = surahItem['id'] as int;

      if (surahItem['verses'] is List) {
        final verses = surahItem['verses'] as List;
        for (var verse in verses) {
             allAyahs.add(Ayah.fromJson(verse, surahId)); // Uses the updated fromJson with normalization
        }
      }
    }
    return allAyahs;
  }
}
