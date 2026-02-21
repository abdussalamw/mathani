import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mushaf_navigation_data.dart';

/// خدمة تحميل بيانات مصحف الشمرلي من ملف JSON
class ShamarlyDataLoader {
  static MushafNavigationData? _cachedData;

  /// تحميل بيانات التنقل من ملف JSON
  static Future<MushafNavigationData> loadFromJson() async {
    // استخدام الـ cache إذا كانت البيانات محملة مسبقاً
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      // قراءة ملف JSON من assets
      final jsonString = await rootBundle.loadString(
        'assets/data/shamerly_quran_complete.json',
      );
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      // استخراج البيانات
      final Map<int, int> surahToPage = {};
      final Map<int, JuzInfo> juzData = {};
      final Map<int, PageInfo> pageData = {};
      final Map<String, int> ayahToPage = {};
      
      final pages = data['pages'] as List<dynamic>;
      
      for (var pageJson in pages) {
        // Fix: JSON starts at page 2 (Fatiha), but our system expects Page 1.
        // Shift all pages by -1 to align with the 1-based Image system.
        final pageNum = (pageJson['page'] as int) - 1;
        final surahs = List<int>.from(pageJson['suras'] as List);
        final ayahs = pageJson['ayahs'] as List<dynamic>;
        
        // Filter out empty ornament ayahs
        final validAyahs = ayahs.where((a) => (a['text'] as String).trim().isNotEmpty).toList();
        
        // Fix Fatiha chaotic numbering
        if (surahs.contains(1)) {
          for (var a in validAyahs) {
            if (a['sura'] == 1 && a['ayah_index'] is int) {
               a['ayah'] = a['ayah_index'];
            }
          }
        }
        
        // بناء surahToPage (أول ظهور للسورة)
        for (var surahNum in surahs) {
          if (!surahToPage.containsKey(surahNum)) {
            surahToPage[surahNum] = pageNum;
          }
        }

        // بناء ayahToPage
        for (var ayah in validAyahs) {
          final s = ayah['sura'] as int;
          final a = ayah['ayah'] as int;
          ayahToPage['$s:$a'] = pageNum;
        }
        
        // استخراج نطاق الآيات
        int startSurah = 0;
        int startAyah = 0;
        int endSurah = 0;
        int endAyah = 0;

        List<dynamic> sortedAyahs = [];
        
        if (validAyahs.isNotEmpty) {
          sortedAyahs = List.from(validAyahs)..sort((a, b) {
            final sA = a['sura'] as int;
            final sB = b['sura'] as int;
            if (sA != sB) return sA.compareTo(sB);
            final yA = a['ayah'] as int;
            final yB = b['ayah'] as int;
            return yA.compareTo(yB);
          });
          
          final first = sortedAyahs.first as Map<String, dynamic>;
          final last = sortedAyahs.last as Map<String, dynamic>;
          
          startSurah = first['sura'] as int;
          startAyah = first['ayah'] as int;
          endSurah = last['sura'] as int;
          endAyah = last['ayah'] as int;
        }

        // بناء pageData
        pageData[pageNum] = PageInfo(
          page: pageNum,
          juz: pageJson['juz'] as int,
          hizb: pageJson['hizb'] as int,
          quarter: pageJson['quarter'] as int,
          surahs: surahs,
          startSurah: startSurah,
          startAyah: startAyah,
          endSurah: endSurah,
          endAyah: endAyah,
        );
        
        // بناء juzData (أول صفحة في كل جزء)
        final juzNum = pageJson['juz'] as int;
        if (!juzData.containsKey(juzNum) && sortedAyahs.isNotEmpty) {
          final firstAyah = sortedAyahs.first as Map<String, dynamic>;
          juzData[juzNum] = JuzInfo(
            number: juzNum,
            startPage: pageNum,
            startSurah: firstAyah['sura'] as int,
            startAyah: firstAyah['ayah'] as int,
            surahName: _getSurahName(firstAyah['sura'] as int),
          );
        }
      }
      
      _cachedData = MushafNavigationData(
        mushafId: 'shamarly_15lines',
        totalPages: 521,
        surahToPage: surahToPage,
        juzData: juzData,
        pageData: pageData,
        ayahToPage: ayahToPage,
      );
      
      return _cachedData!;
    } catch (e) {
      throw Exception('فشل تحميل بيانات مصحف الشمرلي: $e');
    }
  }

  /// الحصول على اسم السورة من رقمها
  static String _getSurahName(int surahNumber) {
    const surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
      'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
      'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص',
      'الزمر', 'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق', 'الذاريات', 'الطور',
      'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر',
      'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم',
      'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن', 'المزمل',
      'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق',
      'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى',
      'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون',
      'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس'
    ];
    
    if (surahNumber >= 1 && surahNumber <= 114) {
      return surahNames[surahNumber - 1];
    }
    return '';
  }

  /// مسح الـ cache
  static void clearCache() {
    _cachedData = null;
  }
}
