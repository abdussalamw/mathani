import 'package:flutter/material.dart';
import '../models/mushaf_navigation_data.dart';
import '../services/shamarly_data_loader.dart';
import '../../presentation/providers/mushaf_metadata_provider.dart';

/// مزود بيانات التنقل الديناميكي لجميع المصاحف
class MushafNavigationProvider extends ChangeNotifier {
  MushafNavigationData? _currentNavigationData;
  String? _currentMushafId;
  bool _isLoading = false;

  MushafNavigationData? get currentNavigationData => _currentNavigationData;
  String? get currentMushafId => _currentMushafId;
  bool get isLoading => _isLoading;

  /// تحديث المصحف وتحميل بياناته
  Future<void> updateMushaf(String mushafId) async {
    if (_currentMushafId == mushafId && _currentNavigationData != null) {
      return; // البيانات محملة مسبقاً
    }

    _isLoading = true;
    _currentMushafId = mushafId;
    notifyListeners();

    try {
      if (mushafId == 'shamarly_15lines') {
        _currentNavigationData = await ShamarlyDataLoader.loadFromJson();
      } else {
        // مصحف المدينة (الافتراضي)
        _currentNavigationData = _loadMadaniData();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات المصحف: $e');
      // fallback لمصحف المدينة
      _currentNavigationData = _loadMadaniData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحميل بيانات مصحف المدينة (604 صفحة)
  MushafNavigationData _loadMadaniData() {
    // خريطة السور إلى الصفحات (مصحف المدينة)
    const surahToPage = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
      11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
      21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
      31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
      41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
      61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
      71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
      81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
      91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599, 100: 599,
      101: 600, 102: 600, 103: 601, 104: 601, 105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603,
      111: 603, 112: 604, 113: 604, 114: 604
    };

    // بيانات الأجزاء (مصحف المدينة)
    final juzData = {
      1: JuzInfo(number: 1, startPage: 1, startSurah: 1, startAyah: 1, surahName: 'الفاتحة'),
      2: JuzInfo(number: 2, startPage: 22, startSurah: 2, startAyah: 142, surahName: 'البقرة'),
      3: JuzInfo(number: 3, startPage: 42, startSurah: 2, startAyah: 253, surahName: 'البقرة'),
      4: JuzInfo(number: 4, startPage: 62, startSurah: 3, startAyah: 93, surahName: 'آل عمران'),
      5: JuzInfo(number: 5, startPage: 82, startSurah: 4, startAyah: 24, surahName: 'النساء'),
      6: JuzInfo(number: 6, startPage: 102, startSurah: 4, startAyah: 148, surahName: 'النساء'),
      7: JuzInfo(number: 7, startPage: 122, startSurah: 5, startAyah: 82, surahName: 'المائدة'),
      8: JuzInfo(number: 8, startPage: 142, startSurah: 6, startAyah: 111, surahName: 'الأنعام'),
      9: JuzInfo(number: 9, startPage: 162, startSurah: 7, startAyah: 88, surahName: 'الأعراف'),
      10: JuzInfo(number: 10, startPage: 182, startSurah: 8, startAyah: 41, surahName: 'الأنفال'),
      11: JuzInfo(number: 11, startPage: 202, startSurah: 9, startAyah: 93, surahName: 'التوبة'),
      12: JuzInfo(number: 12, startPage: 222, startSurah: 11, startAyah: 6, surahName: 'هود'),
      13: JuzInfo(number: 13, startPage: 242, startSurah: 12, startAyah: 53, surahName: 'يوسف'),
      14: JuzInfo(number: 14, startPage: 262, startSurah: 15, startAyah: 1, surahName: 'الحجر'),
      15: JuzInfo(number: 15, startPage: 282, startSurah: 17, startAyah: 1, surahName: 'الإسراء'),
      16: JuzInfo(number: 16, startPage: 302, startSurah: 18, startAyah: 75, surahName: 'الكهف'),
      17: JuzInfo(number: 17, startPage: 322, startSurah: 21, startAyah: 1, surahName: 'الأنبياء'),
      18: JuzInfo(number: 18, startPage: 342, startSurah: 23, startAyah: 1, surahName: 'المؤمنون'),
      19: JuzInfo(number: 19, startPage: 362, startSurah: 25, startAyah: 21, surahName: 'الفرقان'),
      20: JuzInfo(number: 20, startPage: 382, startSurah: 27, startAyah: 56, surahName: 'النمل'),
      21: JuzInfo(number: 21, startPage: 402, startSurah: 29, startAyah: 46, surahName: 'العنكبوت'),
      22: JuzInfo(number: 22, startPage: 422, startSurah: 33, startAyah: 31, surahName: 'الأحزاب'),
      23: JuzInfo(number: 23, startPage: 442, startSurah: 36, startAyah: 28, surahName: 'يس'),
      24: JuzInfo(number: 24, startPage: 462, startSurah: 39, startAyah: 32, surahName: 'الزمر'),
      25: JuzInfo(number: 25, startPage: 482, startSurah: 41, startAyah: 47, surahName: 'فصلت'),
      26: JuzInfo(number: 26, startPage: 502, startSurah: 46, startAyah: 1, surahName: 'الأحقاف'),
      27: JuzInfo(number: 27, startPage: 522, startSurah: 51, startAyah: 31, surahName: 'الذاريات'),
      28: JuzInfo(number: 28, startPage: 542, startSurah: 58, startAyah: 1, surahName: 'المجادلة'),
      29: JuzInfo(number: 29, startPage: 562, startSurah: 67, startAyah: 1, surahName: 'الملك'),
      30: JuzInfo(number: 30, startPage: 582, startSurah: 78, startAyah: 1, surahName: 'النبأ'),
    };

    // بيانات الصفحات مع أرقام السور
    final pageData = <int, PageInfo>{};
    for (int i = 1; i <= 604; i++) {
      // حساب الجزء من رقم الصفحة
      int juz = ((i - 1) ~/ 20) + 1;
      if (juz > 30) juz = 30;
      
      // إيجاد السور الموجودة في هذه الصفحة
      List<int> surahs = [];
      for (var entry in surahToPage.entries) {
        if (entry.value == i) {
          surahs.add(entry.key);
        }
      }
      // إذا لم نجد سورة تبدأ في هذه الصفحة، نجد السورة الحالية
      if (surahs.isEmpty) {
        for (var entry in surahToPage.entries.toList().reversed) {
          if (entry.value <= i) {
            surahs.add(entry.key);
            break;
          }
        }
      }
      
      pageData[i] = PageInfo(
        page: i,
        juz: juz,
        hizb: ((i - 1) ~/ 10) + 1,
        quarter: ((i - 1) ~/ 5) + 1,
        surahs: surahs,
      );
    }

    return MushafNavigationData(
      mushafId: 'madani_font_v1',
      totalPages: 604,
      surahToPage: surahToPage,
      juzData: juzData,
      pageData: pageData,
    );
  }

  /// الحصول على رقم الصفحة من رقم السورة
  int? getPageForSurah(int surahNumber) {
    return _currentNavigationData?.getPageForSurah(surahNumber);
  }

  /// الحصول على رقم الصفحة من الآية
  int? getPageForAyah(int surahNumber, int ayahNumber) {
    return _currentNavigationData?.getPageForAyah(surahNumber, ayahNumber);
  }



  /// الحصول على معلومات الجزء
  JuzInfo? getJuzInfo(int juzNumber) {
    return _currentNavigationData?.getJuzInfo(juzNumber);
  }

  /// الحصول على معلومات الصفحة
  PageInfo? getPageInfo(int pageNumber) {
    return _currentNavigationData?.getPageInfo(pageNumber);
  }

  /// التحقق من صحة رقم الصفحة
  bool isValidPage(int page) {
    return _currentNavigationData?.isValidPage(page) ?? false;
  }

  /// الحصول على إجمالي عدد الصفحات
  int get totalPages {
    return _currentNavigationData?.totalPages ?? 604;
  }

  /// الحصول على قائمة الأجزاء
  List<JuzInfo> get juzList {
    if (_currentNavigationData == null) return [];
    return _currentNavigationData!.juzData.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }
}
