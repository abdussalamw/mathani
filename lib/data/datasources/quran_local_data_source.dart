import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranLocalDataSource {
  static final QuranLocalDataSource _instance = QuranLocalDataSource._internal();
  static QuranLocalDataSource get instance => _instance;
  
  QuranLocalDataSource._internal();
  
  // Cache للبيانات المحملة
  List<dynamic>? _cachedData;
  
  /// تحميل البيانات من assets
  Future<List<dynamic>> _loadData() async {
    if (_cachedData != null) return _cachedData!;
    
    final jsonString = await rootBundle.loadString('assets/data/quran_madani.json');
    _cachedData = json.decode(jsonString) as List<dynamic>;
    return _cachedData!;
  }
  
  /// جلب جميع السور
  Future<List<Surah>> loadAllSurahs() async {
    final data = await _loadData();
    final Map<int, Surah> surahsMap = {};
    
    // المرور على كل العناصر وجمع بيانات السور
    for (var item in data) {
      if (item is! Map || item.isEmpty) continue;
      
      // كل عنصر يحتوي على رقم السورة كمفتاح
      item.forEach((key, value) {
        if (key == 'juzNumber') return; // تخطي juzNumber
        
        final chapterNumber = int.tryParse(key);
        if (chapterNumber == null) return;
        
        if (value is Map<String, dynamic>) {
          if (!surahsMap.containsKey(chapterNumber)) {
            surahsMap[chapterNumber] = Surah()
              ..number = chapterNumber
              ..nameArabic = value['titleAr'] ?? ''
              ..nameEnglish = value['titleEn'] ?? ''
              ..nameEnglishTranslation = value['titleEn'] ?? ''
              ..numberOfAyahs = value['verseCount'] ?? 0
              ..revelationType = _getRevelationType(chapterNumber);
          }
        }
      });
    }
    
    return surahsMap.values.toList()..sort((a, b) => a.number.compareTo(b.number));
  }
  
  /// جلب آيات سورة معينة
  Future<List<Ayah>> loadAyahsForSurah(int surahNumber) async {
    final data = await _loadData();
    final Map<int, Ayah> ayahsMap = {};
    
    for (var item in data) {
      if (item is! Map || item.isEmpty) continue;
      
      item.forEach((key, value) {
        if (key == 'juzNumber') return;
        
        final chapterNumber = int.tryParse(key);
        if (chapterNumber != surahNumber) return;
        
        if (value is Map<String, dynamic> && value['text'] is List) {
          final verses = value['text'] as List;
          for (var verse in verses) {
            if (verse is! Map<String, dynamic>) continue;
            
            final verseNumber = int.tryParse(verse['verseNumber']?.toString() ?? '');
            if (verseNumber == null) continue;
            
            if (!ayahsMap.containsKey(verseNumber)) {
              ayahsMap[verseNumber] = Ayah()
                ..surahNumber = surahNumber
                ..ayahNumber = verseNumber
                ..text = verse['text'] ?? ''
                ..page = 1; // سيتم تحديثه لاحقاً
            }
          }
        }
      });
    }
    
    return ayahsMap.values.toList()..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
  }
  
  /// تحديد نوع الوحي (مكي/مدني)
  String _getRevelationType(int surahNumber) {
    // السور المدنية
    const medananSurahs = [2, 3, 4, 5, 8, 9, 22, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 110];
    return medananSurahs.contains(surahNumber) ? 'Medinan' : 'Meccan';
  }
}
