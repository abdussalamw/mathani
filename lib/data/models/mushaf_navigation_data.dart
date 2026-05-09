/// نموذج بيانات التنقل الموحد لجميع المصاحف
class MushafNavigationData {
  final String mushafId;
  final int totalPages;
  final Map<int, int> surahToPage;      // رقم السورة -> رقم الصفحة الأولى
  final Map<int, JuzInfo> juzData;      // رقم الجزء -> معلومات الجزء
  final Map<int, PageInfo> pageData;    // رقم الصفحة -> معلومات الصفحة
  final Map<String, int>? ayahToPage;   // "surah:ayah" -> page (اختياري)

  MushafNavigationData({
    required this.mushafId,
    required this.totalPages,
    required this.surahToPage,
    required this.juzData,
    required this.pageData,
    this.ayahToPage,
  });

  /// الحصول على رقم الصفحة من رقم السورة
  int? getPageForSurah(int surahNumber) {
    return surahToPage[surahNumber];
  }

  int? getPageForAyah(int surahNumber, int ayahNumber) {
    if (ayahToPage != null) {
      return ayahToPage!['$surahNumber:$ayahNumber'];
    }
    
    // Check ranges in PageData
    for (final page in pageData.values) {
      if (page.startSurah == 0) continue;

      bool inRange = false;
      
      // Case A: Page within single Surah
      if (page.startSurah == page.endSurah) {
        if (surahNumber == page.startSurah) {
          if (ayahNumber >= page.startAyah && ayahNumber <= page.endAyah) {
            inRange = true;
          }
        }
      }
      // Case B: Page spans multiple Surahs
      else {
        // 1. First Surah part
        if (surahNumber == page.startSurah && ayahNumber >= page.startAyah) {
          inRange = true;
        }
        // 2. Last Surah part
        else if (surahNumber == page.endSurah && ayahNumber <= page.endAyah) {
          inRange = true;
        }
        // 3. Middle Surahs (Full)
        else if (surahNumber > page.startSurah && surahNumber < page.endSurah) {
          inRange = true;
        }
      }

      if (inRange) return page.page;
    }

    // Fallback
    return surahToPage[surahNumber];
  }

  /// الحصول على معلومات الجزء
  JuzInfo? getJuzInfo(int juzNumber) {
    return juzData[juzNumber];
  }

  /// الحصول على معلومات الصفحة
  PageInfo? getPageInfo(int pageNumber) {
    return pageData[pageNumber];
  }

  /// التحقق من صحة رقم الصفحة
  bool isValidPage(int page) {
    return page >= 1 && page <= totalPages;
  }
}

/// معلومات الجزء
class JuzInfo {
  final int number;
  final int startPage;
  final int startSurah;
  final int startAyah;
  final String surahName;

  JuzInfo({
    required this.number,
    required this.startPage,
    required this.startSurah,
    required this.startAyah,
    required this.surahName,
  });
}

/// معلومات الصفحة
class PageInfo {
  final int page;
  final int juz;
  final int hizb;
  final int quarter;
  final List<int> surahs;
  // Dynamic Ayah Range
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  PageInfo({
    required this.page,
    required this.juz,
    required this.hizb,
    required this.quarter,
    required this.surahs,
    this.startSurah = 0,
    this.startAyah = 0,
    this.endSurah = 0,
    this.endAyah = 0,
  });
}
