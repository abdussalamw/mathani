/// نماذج البيانات المحسّنة لمصحف المدينة القديم (QPC V1)
/// 
/// هذا الملف يحتوي على النماذج الأساسية لنظام QPC V1
/// مع دعم كامل للخطوط PUA-based والتخطيط المعقد

import 'package:flutter/foundation.dart';

/// نموذج صفحة QPC V1 كاملة
class QPCV1Page {
  final int pageNumber;
  final List<QPCV1Line> lines;
  final int juz;
  final int? surahNumber;
  
  const QPCV1Page({
    required this.pageNumber,
    required this.lines,
    required this.juz,
    this.surahNumber,
  });
  
  /// عدد الأسطر في الصفحة
  int get lineCount => lines.length;
  
  /// هل الصفحة تحتوي على بداية سورة؟
  bool get hasSurahStart => lines.any((line) => line.type == QPCV1LineType.surahName);
  
  /// الحصول على رأس السورة إن وُجد
  QPCV1Line? get surahHeader => 
      lines.firstWhere((line) => line.type == QPCV1LineType.surahName, 
                      orElse: () => lines.first);
}

/// أنواع الأسطر في المصحف
enum QPCV1LineType {
  /// رأس السورة (اسم السورة)
  surahName,
  
  /// البسملة
  basmala,
  
  /// سطر عادي من آيات القرآن
  ayahText,
  
  /// سطر فارغ (للتباعد)
  empty,
}

/// نموذج سطر واحد في الصفحة
class QPCV1Line {
  /// رقم السطر في الصفحة (1-15)
  final int lineNumber;
  
  /// نوع السطر
  final QPCV1LineType type;
  
  /// الكلمات في هذا السطر
  final List<QPCV1Word> words;
  
  /// رقم السورة (للأسطر العادية)
  final int? surahNumber;
  
  /// رقم الآية الأولى في السطر
  final int? firstAyahNumber;
  
  /// رقم الآية الأخيرة في السطر
  final int? lastAyahNumber;
  
  const QPCV1Line({
    required this.lineNumber,
    required this.type,
    required this.words,
    this.surahNumber,
    this.firstAyahNumber,
    this.lastAyahNumber,
  });
  
  /// هل السطر فارغ؟
  bool get isEmpty => words.isEmpty;
  
  /// عدد الكلمات في السطر
  int get wordCount => words.length;
  
  /// بناء النص الكامل للسطر
  String get text {
    if (type == QPCV1LineType.surahName && surahNumber != null) {
      // رموز رؤوس السور في QPC V1
      return _getSurahHeaderGlyph(surahNumber!);
    }
    
    if (type == QPCV1LineType.basmala) {
      // رمز البسملة في QPC V1
      return String.fromCharCode(0xFD3E);
    }
    
    // للأسطر العادية: دمج الكلمات
    return words.map((w) => w.glyph).join('');
  }
  
  /// الحصول على رمز رأس السورة
  static String _getSurahHeaderGlyph(int surahNumber) {
    // QPC V1 يستخدم رموز خاصة لرؤوس السور
    // النطاق: 0xFD50 - 0xFDCF
    // كل سورة لها رمز خاص
    final glyphCode = 0xFD50 + (surahNumber - 1);
    return String.fromCharCode(glyphCode);
  }
  
  /// إنشاء سطر فارغ
  factory QPCV1Line.empty(int lineNumber) {
    return QPCV1Line(
      lineNumber: lineNumber,
      type: QPCV1LineType.empty,
      words: [],
    );
  }
  
  /// إنشاء سطر رأس سورة
  factory QPCV1Line.surahHeader(int lineNumber, int surahNumber) {
    return QPCV1Line(
      lineNumber: lineNumber,
      type: QPCV1LineType.surahName,
      words: [],
      surahNumber: surahNumber,
    );
  }
  
  /// إنشاء سطر بسملة
  factory QPCV1Line.basmala(int lineNumber) {
    return QPCV1Line(
      lineNumber: lineNumber,
      type: QPCV1LineType.basmala,
      words: [],
    );
  }
}

/// نموذج كلمة واحدة في المصحف
class QPCV1Word {
  /// معرّف الكلمة الفريد عبر المصحف
  final int globalWordId;
  
  /// رقم السورة
  final int surahNumber;
  
  /// رقم الآية
  final int ayahNumber;
  
  /// رقم الكلمة في الآية (1-based)
  final int wordNumberInAyah;
  
  /// الرمز (Glyph) من الخط
  final String glyph;
  
  /// النص الأصلي للكلمة (للمرجعية)
  final String? originalText;
  
  const QPCV1Word({
    required this.globalWordId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordNumberInAyah,
    required this.glyph,
    this.originalText,
  });
  
  /// مفتاح فريد للكلمة (للـ Debugging)
  String get key => '$surahNumber:$ayahNumber:$wordNumberInAyah';
  
  @override
  String toString() => 'QPCV1Word($key, glyph=${glyph.codeUnits})';
}

/// إحصائيات مصحف QPC V1
class QPCV1Statistics {
  static const int totalPages = 604;
  static const int linesPerPage = 15;
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  
  /// حساب عدد الكلمات التقريبي
  /// (المصحف يحتوي على حوالي 77,430 كلمة)
  static const int approximateWordCount = 77430;
  
  /// أول صفحة لكل جزء
  static const Map<int, int> juzStartPages = {
    1: 1,
    2: 22,
    3: 42,
    4: 62,
    5: 82,
    6: 102,
    7: 122,
    8: 142,
    9: 162,
    10: 182,
    11: 202,
    12: 222,
    13: 242,
    14: 262,
    15: 282,
    16: 302,
    17: 322,
    18: 342,
    19: 362,
    20: 382,
    21: 402,
    22: 422,
    23: 442,
    24: 462,
    25: 482,
    26: 502,
    27: 522,
    28: 542,
    29: 562,
    30: 582,
  };
  
  /// الحصول على رقم الجزء من رقم الصفحة
  static int getJuzFromPage(int pageNumber) {
    for (var entry in juzStartPages.entries.toList().reversed) {
      if (pageNumber >= entry.value) {
        return entry.key;
      }
    }
    return 1;
  }
}

/// نطاقات الترميز في خطوط QPC V1
class QPCV1GlyphRanges {
  /// نطاق الكلمات القرآنية (Private Use Area)
  /// يبدأ من 0xE000 وينتهي عند 0xF8FF
  static const int wordGlyphStart = 0xE000;
  static const int wordGlyphEnd = 0xF8FF;
  
  /// نطاق رؤوس السور
  /// 114 سورة، كل واحدة لها رمز خاص
  static const int surahHeaderStart = 0xFD50;
  static const int surahHeaderEnd = 0xFDC1; // 0xFD50 + 113
  
  /// رمز البسملة
  static const int basmalaGlyph = 0xFD3E;
  
  /// رموز نهاية الآيات (دائرية)
  static const int ayahEndStart = 0x06DD;
  
  /// رموز علامات الوقف
  static const int pauseMarkStart = 0x06D6;
  
  /// التحقق من أن الرمز في نطاق الكلمات
  static bool isWordGlyph(int charCode) {
    return charCode >= wordGlyphStart && charCode <= wordGlyphEnd;
  }
  
  /// التحقق من أن الرمز في نطاق رؤوس السور
  static bool isSurahHeader(int charCode) {
    return charCode >= surahHeaderStart && charCode <= surahHeaderEnd;
  }
}
