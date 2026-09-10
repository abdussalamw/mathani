/// تقييم كلمة من التلاوة
enum WordVerdict {
  correct,    // صحيحة
  acceptable, // مقبولة (صحيحة بملاحظات)
  incorrect,  // خطأ
  skipped,    // لم تُقرأ
}

/// نتيجة تحليل كلمة واحدة من التلاوة
/// نتيجة تحليل كلمة واحدة من التلاوة
class WordResult {
  /// الكلمة كما نطقها المستخدم (من ASR)
  final String spokenWord;

  /// الكلمة الصحيحة من المصحف
  final String expectedWord;

  /// رقم السورة
  final int surahNumber;

  /// رقم الآية
  final int ayahNumber;

  /// ترتيب الكلمة في الآية (0-indexed)
  final int wordIndex;

  /// التقييم العام
  final WordVerdict verdict;

  /// درجة الثقة (0.0 - 1.0)
  final double confidence;

  /// وقت البداية بالمللي ثانية (من توقيتات Whisper)
  final int? startTimeMs;

  /// وقت النهاية بالمللي ثانية
  final int? endTimeMs;

  const WordResult({
    required this.spokenWord,
    required this.expectedWord,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.verdict,
    this.confidence = 1.0,
    this.startTimeMs,
    this.endTimeMs,
  });

  /// هل الكلمة صحيحة؟
  bool get isCorrect => verdict == WordVerdict.correct;

  /// هل الكلمة مقبولة (صحيحة أو بملاحظات)؟
  bool get isAcceptable =>
      verdict == WordVerdict.correct || verdict == WordVerdict.acceptable;

  Map<String, dynamic> toJson() => {
        'spoken': spokenWord,
        'expected': expectedWord,
        'surah': surahNumber,
        'ayah': ayahNumber,
        'wordIndex': wordIndex,
        'verdict': verdict.name,
        'confidence': confidence,
        'startMs': startTimeMs,
        'endMs': endTimeMs,
      };
}

/// نتيجة تحليل جلسة تسميع كاملة
class RecitationResult {
  /// قائمة نتائج الكلمات
  final List<WordResult> words;

  /// السورة المكتشفة / المحددة
  final int surahNumber;

  /// اسم السورة
  final String surahName;

  /// بداية الآيات
  final int startAyah;

  /// نهاية الآيات
  final int endAyah;

  /// مدة التلاوة (مللي ثانية)
  final int durationMs;

  /// النص الخام من ASR
  final String rawTranscript;

  /// وقت التحليل
  final DateTime analyzedAt;

  /// مسار ملف الصوت المسجل
  final String? audioPath;

  RecitationResult({
    required this.words,
    required this.surahNumber,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.durationMs,
    required this.rawTranscript,
    DateTime? analyzedAt,
    this.audioPath,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// إجمالي عدد الكلمات
  int get totalWords => words.length;

  /// عدد الكلمات الصحيحة
  int get correctWords =>
      words.where((w) => w.verdict == WordVerdict.correct).length;

  /// عدد الكلمات المقبولة
  int get acceptableWords =>
      words.where((w) => w.verdict == WordVerdict.acceptable).length;

  /// عدد الكلمات الخاطئة
  int get incorrectWords =>
      words.where((w) => w.verdict == WordVerdict.incorrect).length;

  /// عدد الكلمات المتجاوزة
  int get skippedWords =>
      words.where((w) => w.verdict == WordVerdict.skipped).length;

  /// نسبة الدقة الإجمالية (0.0 - 1.0)
  double get accuracy {
    if (totalWords == 0) return 0.0;
    return (correctWords + acceptableWords * 0.7) / totalWords;
  }

  /// نسبة الدقة كنسبة مئوية
  int get accuracyPercent => (accuracy * 100).round();

  /// التقييم العام للجلسة
  String get overallGrade {
    if (accuracy >= 0.95) return 'ممتاز';
    if (accuracy >= 0.85) return 'جيد جداً';
    if (accuracy >= 0.70) return 'جيد';
    if (accuracy >= 0.50) return 'مقبول';
    return 'يحتاج تحسين';
  }

  /// نتائج مجمعة حسب الآية
  Map<int, List<WordResult>> get wordsByAyah {
    final map = <int, List<WordResult>>{};
    for (final word in words) {
      map.putIfAbsent(word.ayahNumber, () => []).add(word);
    }
    return map;
  }

  Map<String, dynamic> toJson() => {
        'surah': surahNumber,
        'surahName': surahName,
        'startAyah': startAyah,
        'endAyah': endAyah,
        'durationMs': durationMs,
        'rawTranscript': rawTranscript,
        'accuracy': accuracy,
        'totalWords': totalWords,
        'correctWords': correctWords,
        'words': words.map((w) => w.toJson()).toList(),
        'analyzedAt': analyzedAt.toIso8601String(),
        'audioPath': audioPath,
      };
}
