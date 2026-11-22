// lib/core/services/recitation/recitation_models.dart
// ═══════════════════════════════════════════════════════════════════════════════
// نماذج بيانات التسميع الفونيمي اللحظي وأحكام التجويد
//
// مستلهم ومطور استناداً إلى حزمة recite_quran (v1.0.5)
// مرخصة لوجه الله تعالى (100% Free / No-Profit).
// ═══════════════════════════════════════════════════════════════════════════════

/// يمثل حكماً تجويدياً في مقطع من الآية (كالمدود والقلقلة).
class TajweedRuleOccurrence {
  final int ruleId;
  final int offset;
  final int span;
  final String ruleNameAr;
  final String ruleNameEn;

  const TajweedRuleOccurrence({
    required this.ruleId,
    required this.offset,
    required this.span,
    required this.ruleNameAr,
    required this.ruleNameEn,
  });

  factory TajweedRuleOccurrence.fromList(
    List<dynamic> ruleList,
    Map<String, dynamic> ruleNames,
  ) {
    final offset = (ruleList[0] as num).toInt();
    final ruleId = (ruleList[1] as num).toInt();
    final span = (ruleList[2] as num).toInt();

    final nameEntry = ruleNames[ruleId.toString()] as Map<String, dynamic>?;
    final ar = nameEntry?['ar'] as String? ?? 'حكم تجويدي';
    final en = nameEntry?['en'] as String? ?? 'Tajweed Rule';

    return TajweedRuleOccurrence(
      ruleId: ruleId,
      offset: offset,
      span: span,
      ruleNameAr: ar,
      ruleNameEn: en,
    );
  }
}

/// يمثل بيانات الآية الصوتية المرجعية (نص، فونيمات، كلمات، وأحكام تجويد).
class QuranVersePhonemes {
  final String verseKey; // e.g. "1:1"
  final String ayaText;
  final String ayaPhoneme;
  final List<String> ayaPhonemesList;
  final String surahNameAr;
  final String surahNameEn;
  final List<TajweedRuleOccurrence> rules;

  const QuranVersePhonemes({
    required this.verseKey,
    required this.ayaText,
    required this.ayaPhoneme,
    required this.ayaPhonemesList,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.rules,
  });

  factory QuranVersePhonemes.fromJson(
    String key,
    Map<String, dynamic> json,
    Map<String, dynamic> ruleNames,
  ) {
    final rulesList = (json['rules'] as List<dynamic>? ?? [])
        .map(
          (r) => TajweedRuleOccurrence.fromList(r as List<dynamic>, ruleNames),
        )
        .toList();

    final phonemesList = (json['aya_phonemes_list'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return QuranVersePhonemes(
      verseKey: key,
      ayaText: json['aya_text'] as String? ?? '',
      ayaPhoneme: json['aya_phoneme'] as String? ?? '',
      ayaPhonemesList: phonemesList,
      surahNameAr: json['suraname_ar'] as String? ?? '',
      surahNameEn: json['suraname_en'] as String? ?? '',
      rules: rulesList,
    );
  }
}

/// حالة مطابقة الكلمة أثناء التسميع اللحظي.
enum WordRecitationStatus {
  unspoken, // لم تُقرأ بعد
  current, // يقرأها الآن
  matched, // قُرئت بنجاح
  omitted, // تم تجاوزها أو نسيانها
  incorrect, // ثبت الاختلاف بعد محاذاة الكلمات اللاحقة
  unconfirmed, // لم تكفِ نتيجة التعرّف للحكم على الكلمة
  omittedVerse, // ثبت الانتقال إلى الآية التي تلي الآية المتجاوزة
  added, // ظهر لفظ مرجعي زائد قبل موضع متابعة مؤكد
  corrected, // أعاد القارئ كلمة ملتبسة وطابق لفظها المرجع
}

/// نتيجة مطابقة لحظية لكلمة قرآنية.
class WordMatchEvent {
  final int wordIndex;
  final String wordText;
  final String referencePhonemes;
  final String recognizedPhonemes;
  final double similarity;
  final WordRecitationStatus status;

  /// Half-open UTF-16 offsets in the normalized cumulative hypothesis.
  final int? phonemeStart;
  final int? phonemeEnd;

  const WordMatchEvent({
    required this.wordIndex,
    required this.wordText,
    required this.referencePhonemes,
    required this.recognizedPhonemes,
    required this.similarity,
    required this.status,
    this.phonemeStart,
    this.phonemeEnd,
  });

  WordMatchEvent asUnconfirmed() => WordMatchEvent(
    wordIndex: wordIndex,
    wordText: wordText,
    referencePhonemes: referencePhonemes,
    recognizedPhonemes: recognizedPhonemes,
    similarity: 0,
    status: WordRecitationStatus.unconfirmed,
    phonemeStart: phonemeStart,
    phonemeEnd: phonemeEnd,
  );
}
