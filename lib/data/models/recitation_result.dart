import 'dart:convert';

import 'recitation_session.dart';

/// تقييم كلمة من التلاوة
enum WordVerdict {
  correct, // صحيحة
  acceptable, // مقبولة (صحيحة بملاحظات)
  incorrect, // خطأ
  skipped, // لم تُقرأ
  unconfirmed, // لم تتوفر أدلة كافية لتقييمها
}

enum RecitationReviewKind {
  skippedWord,
  skippedAyah,
  replacedWord,
  addedWord,
  corrected,
  letter,
  vowel,
  unclassified,
  unconfirmed;

  String get label => switch (this) {
    skippedWord => 'تجاوز كلمة',
    skippedAyah => 'تجاوز آية',
    replacedWord => 'تغيير كلمة',
    addedWord => 'إضافة كلمة',
    corrected => 'صُحّحت أثناء التسميع',
    letter => 'حرف مختلف',
    vowel => 'حركة مختلفة',
    unclassified => 'غير مصنّفة',
    unconfirmed => 'غير مؤكدة',
  };

  bool get isIssue => this != corrected && this != unconfirmed;
}

typedef RecitationVerseLocation = ({int surahNumber, int ayahNumber});

class RecitationReviewItem {
  RecitationReviewItem._(this.kind, Iterable<WordResult> words)
    : words = List.unmodifiable(words);

  final RecitationReviewKind kind;
  final List<WordResult> words;

  WordResult get word => words.first;
  int get surahNumber => word.surahNumber;
  int get ayahNumber => word.ayahNumber;
  int get wordIndex => word.wordIndex;
  int get count => kind == RecitationReviewKind.skippedAyah ? 1 : words.length;
  String get key => _reviewItemKey(word, kind);
}

String _reviewItemKey(WordResult word, RecitationReviewKind kind) {
  final index = kind == RecitationReviewKind.skippedAyah ? -1 : word.wordIndex;
  return '${word.surahNumber}:${word.ayahNumber}:$index:${kind.name}';
}

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

  /// نوع تفصيلي يُحفظ عند توفر دليل كافٍ لتحديده.
  final RecitationReviewKind? reviewKind;

  /// درجة المطابقة المسجّلة (0.0 - 1.0).
  final double confidence;

  /// وقت البداية بالمللي ثانية ضمن التسجيل.
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
    this.reviewKind,
    this.confidence = 1.0,
    this.startTimeMs,
    this.endTimeMs,
  });

  /// هل الكلمة صحيحة؟
  bool get isCorrect => verdict == WordVerdict.correct;

  /// هل الكلمة مقبولة (صحيحة أو بملاحظات)؟
  bool get isAcceptable =>
      verdict == WordVerdict.correct || verdict == WordVerdict.acceptable;

  RecitationVerseLocation get location =>
      (surahNumber: surahNumber, ayahNumber: ayahNumber);

  RecitationReviewKind? get effectiveReviewKind {
    if (reviewKind != null) return reviewKind;
    return switch (verdict) {
      WordVerdict.correct || WordVerdict.acceptable => null,
      WordVerdict.incorrect ||
      WordVerdict.skipped => RecitationReviewKind.unclassified,
      WordVerdict.unconfirmed => RecitationReviewKind.unconfirmed,
    };
  }

  bool get coversReferenceWord =>
      reviewKind != RecitationReviewKind.addedWord &&
      reviewKind != RecitationReviewKind.skippedAyah;

  Map<String, dynamic> toJson() => {
    'spoken': spokenWord,
    'expected': expectedWord,
    'surah': surahNumber,
    'ayah': ayahNumber,
    'wordIndex': wordIndex,
    'verdict': verdict.name,
    if (reviewKind case final kind?) 'reviewKind': kind.name,
    'confidence': confidence,
    'startMs': startTimeMs,
    'endMs': endTimeMs,
  };
}

typedef _StoredRecitationScore = ({
  double? accuracy,
  String? overallGrade,
  int? gradedWords,
  int? totalWords,
  int? correctWords,
});

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

  /// The Isar identifier once the result has been saved.
  final int? sessionId;

  final _StoredRecitationScore? _storedScore;
  final Set<String> _dismissedReviewItemKeys;

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
  }) : analyzedAt = analyzedAt ?? DateTime.now(),
       sessionId = null,
       _storedScore = null,
       _dismissedReviewItemKeys = const {};

  RecitationResult._fromSession(
    RecitationSession session,
    Map<String, dynamic> json,
    int surah,
  ) : words = _readWords(json['words'], fallbackSurah: surah),
      surahNumber = surah,
      surahName = _nonEmptyString(json['surahName']) ?? session.surahName,
      startAyah =
          _positiveInt(json['startAyah']) ??
          _positiveInt(session.startAyah) ??
          1,
      endAyah =
          _positiveInt(json['endAyah']) ?? _positiveInt(session.endAyah) ?? 1,
      durationMs =
          _nonNegativeInt(json['durationMs']) ??
          (_nonNegativeInt(session.durationSeconds) ?? 0) * 1000,
      rawTranscript = json['rawTranscript'] is String
          ? json['rawTranscript'] as String
          : session.rawTranscript,
      analyzedAt = _readDate(json['analyzedAt']) ?? session.createdAt,
      audioPath = _nonEmptyString(json['audioPath']),
      sessionId = _positiveInt(session.id),
      _storedScore = _readStoredScore(session, json),
      _dismissedReviewItemKeys = _readDismissals(json);

  RecitationResult._withReviewDismissals(
    RecitationResult result,
    this._dismissedReviewItemKeys,
  ) : words = result.words,
      surahNumber = result.surahNumber,
      surahName = result.surahName,
      startAyah = result.startAyah,
      endAyah = result.endAyah,
      durationMs = result.durationMs,
      rawTranscript = result.rawTranscript,
      analyzedAt = result.analyzedAt,
      audioPath = result.audioPath,
      sessionId = result.sessionId,
      _storedScore = result._storedScore;

  /// Reads both old summaries and sessions that carry detailed review data.
  factory RecitationResult.fromSession(RecitationSession session) {
    final json = _readSessionJson(session.resultJson);
    final surah =
        _readSurah(json['surah']) ?? _readSurah(session.surahNumber) ?? 1;
    return RecitationResult._fromSession(session, json, surah);
  }

  RecitationVerseLocation get startLocation =>
      (surahNumber: surahNumber, ayahNumber: startAyah);

  RecitationVerseLocation get endLocation {
    if (words.isNotEmpty && words.last.surahNumber != surahNumber) {
      return words.last.location;
    }
    return (surahNumber: surahNumber, ayahNumber: endAyah);
  }

  Iterable<WordResult> get _canonicalWords =>
      words.where((word) => word.coversReferenceWord);

  /// إجمالي عدد الكلمات
  int get totalWords =>
      _storedScore?.totalWords ??
      switch (_storedScore?.gradedWords) {
        final savedCount? => savedCount + unconfirmedWords,
        null => _canonicalWords.length,
      };

  /// عدد الكلمات الصحيحة
  int get correctWords =>
      _storedScore?.correctWords ??
      _canonicalWords.where((w) => w.verdict == WordVerdict.correct).length;

  /// عدد الكلمات المقبولة
  int get acceptableWords =>
      _canonicalWords.where((w) => w.verdict == WordVerdict.acceptable).length;

  /// عدد الكلمات الخاطئة
  int get incorrectWords => _canonicalWords
      .where(
        (word) =>
            word.verdict == WordVerdict.incorrect &&
            !isWordReviewDismissed(word),
      )
      .length;

  /// عدد الكلمات المتجاوزة
  int get skippedWords => _canonicalWords
      .where(
        (word) =>
            word.verdict == WordVerdict.skipped && !isWordReviewDismissed(word),
      )
      .length;

  int get unconfirmedWords =>
      _canonicalWords.where((w) => w.verdict == WordVerdict.unconfirmed).length;

  int get gradedWords =>
      _storedScore?.gradedWords ??
      (totalWords - unconfirmedWords).clamp(0, totalWords);

  List<RecitationReviewItem> get reviewItems {
    final items = <RecitationReviewItem>[];
    final skippedVerses = <RecitationVerseLocation, List<WordResult>>{};
    for (final word in words) {
      if (word.effectiveReviewKind == RecitationReviewKind.skippedAyah) {
        skippedVerses.putIfAbsent(word.location, () => []).add(word);
      }
    }
    for (final word in words) {
      final kind = word.effectiveReviewKind;
      if (kind == null) continue;
      if (kind == RecitationReviewKind.skippedAyah) {
        final omittedWords = skippedVerses.remove(word.location);
        if (omittedWords != null) {
          items.add(RecitationReviewItem._(kind, omittedWords));
        }
      } else {
        items.add(RecitationReviewItem._(kind, [word]));
      }
    }
    return items;
  }

  bool isReviewItemDismissed(RecitationReviewItem item) =>
      _dismissedReviewItemKeys.isNotEmpty &&
      item.kind.isIssue &&
      _dismissedReviewItemKeys.contains(item.key);

  bool isWordReviewDismissed(WordResult word) {
    if (_dismissedReviewItemKeys.isEmpty) return false;
    final kind = word.effectiveReviewKind;
    return kind != null &&
        kind.isIssue &&
        _dismissedReviewItemKeys.contains(_reviewItemKey(word, kind));
  }

  bool get hasDismissedReviewItems => _dismissedReviewItemKeys.isNotEmpty;

  RecitationReviewItem? reviewIssueForWord(WordResult word) {
    final kind = word.effectiveReviewKind;
    if (kind == null || !kind.isIssue) return null;
    final key = _reviewItemKey(word, kind);
    return reviewItems.where((item) => item.key == key).firstOrNull;
  }

  Iterable<RecitationReviewItem> get activeReviewItems =>
      reviewItems.where((item) => !isReviewItemDismissed(item));

  int get reviewIssueCount => activeReviewItems.fold(
    0,
    (count, item) => count + (item.kind.isIssue ? item.count : 0),
  );

  RecitationResult withReviewItemDismissal(
    RecitationReviewItem item, {
    required bool dismissed,
  }) {
    final key = item.key;
    if (!item.kind.isIssue || !reviewItems.any((entry) => entry.key == key)) {
      throw StateError('تنبيه التسميع غير موجود في هذه الجلسة.');
    }
    final keys = Set.of(_dismissedReviewItemKeys);
    if (dismissed) {
      keys.add(key);
    } else {
      keys.remove(key);
    }
    return RecitationResult._withReviewDismissals(this, Set.unmodifiable(keys));
  }

  /// Writes the review choice into the existing detail payload only.
  static RecitationResult updateSessionReview(
    RecitationSession session,
    RecitationReviewItem item, {
    required bool dismissed,
  }) {
    final result = RecitationResult.fromSession(session)
        .withReviewItemDismissal(item, dismissed: dismissed);
    final json = _readSessionJson(session.resultJson);
    if (result._dismissedReviewItemKeys.isEmpty) {
      json.remove(_dismissalsKey);
    } else {
      json[_dismissalsKey] = result._dismissedReviewItemKeys.toList();
    }
    session.resultJson = jsonEncode(json);
    return result;
  }

  /// نسبة الدقة الإجمالية (0.0 - 1.0)
  double get accuracy {
    final saved = _storedScore?.accuracy;
    if (saved != null) return saved;
    final count = gradedWords;
    if (count == 0) return 0.0;
    return (correctWords + acceptableWords * 0.7) / count;
  }

  /// نسبة الدقة كنسبة مئوية
  int get accuracyPercent => (accuracy * 100).round();

  /// التقييم العام للجلسة
  String get overallGrade {
    final saved = _storedScore?.overallGrade;
    if (saved != null) return saved;
    if (accuracy >= 0.95) return 'ممتاز';
    if (accuracy >= 0.85) return 'جيد جداً';
    if (accuracy >= 0.70) return 'جيد';
    if (accuracy >= 0.50) return 'مقبول';
    return 'يحتاج تحسين';
  }

  Map<RecitationVerseLocation, List<WordResult>> get wordsByVerse {
    final map = <RecitationVerseLocation, List<WordResult>>{};
    for (final word in words) {
      map.putIfAbsent(word.location, () => []).add(word);
    }
    return map;
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
    'overallGrade': overallGrade,
    'totalWords': totalWords,
    'gradedWords': gradedWords,
    'correctWords': correctWords,
    'words': words.map((w) => w.toJson()).toList(),
    'analyzedAt': analyzedAt.toIso8601String(),
    'audioPath': audioPath,
    if (_dismissedReviewItemKeys.isNotEmpty)
      _dismissalsKey: _dismissedReviewItemKeys.toList(),
  };
}

const _dismissalsKey = 'dismissedReviewItems';

Set<String> _readDismissals(Map<String, dynamic> json) {
  final keys = json[_dismissalsKey];
  return keys is List ? Set.unmodifiable(keys.whereType<String>()) : const {};
}

Map<String, dynamic> _readSessionJson(String? source) {
  if (source == null || source.isEmpty) return const {};
  try {
    final json = jsonDecode(source);
    return json is Map<String, dynamic> ? json : const {};
  } on FormatException {
    return const {};
  }
}

final _wordVerdicts = WordVerdict.values.asNameMap();
final _reviewKinds = RecitationReviewKind.values.asNameMap();

List<WordResult> _readWords(Object? json, {required int fallbackSurah}) {
  if (json is! List) return const [];
  final words = <WordResult>[];
  for (final row in json) {
    if (row is! Map<String, dynamic>) continue;
    final ayah = _positiveInt(row['ayah']);
    final index = _nonNegativeInt(row['wordIndex']);
    if (ayah == null || index == null) continue;

    // Keep an unknown legacy verdict neutral.
    final knownVerdict = _wordVerdicts[row['verdict']];
    final verdict = knownVerdict ?? WordVerdict.unconfirmed;
    final startMs = _nonNegativeInt(row['startMs']);
    final endMs = _positiveInt(row['endMs']);
    final hasClip = startMs != null && endMs != null && startMs < endMs;
    words.add(
      WordResult(
        spokenWord: _nonEmptyString(row['spoken']) ?? '',
        expectedWord: _nonEmptyString(row['expected']) ?? '',
        surahNumber: _readSurah(row['surah']) ?? fallbackSurah,
        ayahNumber: ayah,
        wordIndex: index,
        verdict: verdict,
        reviewKind: knownVerdict == null
            ? null
            : _reviewKinds[row['reviewKind']],
        confidence:
            _unitRatio(row['confidence']) ??
            (verdict == WordVerdict.unconfirmed ? 0 : 1),
        startTimeMs: hasClip ? startMs : null,
        endTimeMs: hasClip ? endMs : null,
      ),
    );
  }
  return words;
}

_StoredRecitationScore _readStoredScore(
  RecitationSession session,
  Map<String, dynamic> json,
) {
  final hasSummary =
      session.totalWords > 0 ||
      session.correctWords > 0 ||
      session.accuracyPercent != 0 ||
      session.overallGrade.isNotEmpty;
  final reportedAccuracy = session.accuracyPercent.clamp(0, 100);
  final jsonAccuracy = _unitRatio(json['accuracy']);
  final hasConsistentAccuracy =
      jsonAccuracy != null && (jsonAccuracy * 100).round() == reportedAccuracy;
  return (
    accuracy: hasSummary && !hasConsistentAccuracy
        ? reportedAccuracy / 100
        : jsonAccuracy,
    overallGrade:
        _nonEmptyString(session.overallGrade) ??
        _nonEmptyString(json['overallGrade']),
    gradedWords: hasSummary
        ? _nonNegativeInt(session.totalWords) ?? 0
        : _nonNegativeInt(json['gradedWords']),
    totalWords: _nonNegativeInt(json['totalWords']),
    correctWords: hasSummary
        ? _nonNegativeInt(session.correctWords) ?? 0
        : _nonNegativeInt(json['correctWords']),
  );
}

String? _nonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int? _nonNegativeInt(Object? value) =>
    value is int && value >= 0 ? value : null;

int? _positiveInt(Object? value) => value is int && value > 0 ? value : null;

int? _readSurah(Object? value) =>
    value is int && value >= 1 && value <= 114 ? value : null;

DateTime? _readDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

double? _unitRatio(Object? value) =>
    value is num && value >= 0 && value <= 1 ? value.toDouble() : null;
