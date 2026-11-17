import '../../core/utils/text_utils.dart';
import '../models/recitation_result.dart';
import 'asr_service.dart';

/// تمثيل لكلمة مستهدفة من المصحف
class _TargetWord {
  final int surahNumber;
  final int ayahNumber;
  final int wordIndex;
  final String text;
  final String normalized;
  final String phonetic;

  const _TargetWord({
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.text,
    required this.normalized,
    required this.phonetic,
  });
}

/// نتيجة المطابقة لكلمة واحدة
class MatchedWord {
  final String spokenWord; // الكلمة المنطوقة (أو فارغة إن لم تُقرأ)
  final String expectedWord; // الكلمة الصحيحة من المصحف
  final int surahNumber;
  final int ayahNumber;
  final int wordIndex; // ترتيب الكلمة في الآية
  final double similarity; // نسبة التشابه (0.0 - 1.0)
  final WordVerdict verdict; // تقييم الكلمة
  final int? startMs;
  final int? endMs;

  const MatchedWord({
    required this.spokenWord,
    required this.expectedWord,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.similarity,
    required this.verdict,
    this.startMs,
    this.endMs,
  });
}

/// نتيجة المطابقة الكاملة
class MatchResult {
  final int surahNumber;
  final String surahName;
  final int startAyah;
  final int endAyah;
  final List<MatchedWord> matchedWords;
  final double overallConfidence;

  const MatchResult({
    required this.surahNumber,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.matchedWords,
    required this.overallConfidence,
  });
}

/// خدمة المطابقة والمحاذاة النصية المتقدمة للقرآن الكريم
///
/// تستخدم خوارزمية Needleman-Wunsch Dynamic Programming Alignment
/// لربط النص المستخرج من ASR بكلمات المصحف كلمة بكلمة
/// مع معالجة حالات الحذف (Skipped)، الزيادة (Inserted)، والاستبدال (Incorrect).
class TextMatchingService {
  static final TextMatchingService _instance = TextMatchingService._internal();
  factory TextMatchingService() => _instance;
  TextMatchingService._internal();

  /// المطابقة والمحاذاة الشاملة للنص المنطوق مع نصوص المصحف المستهدفة
  Future<MatchResult> matchTranscript({
    required List<AsrWord> asrWords,
    required Map<int, Map<int, String>> quranText,
    int? hintSurah,
    int? hintStartAyah,
    int? hintEndAyah,
  }) async {
    if (quranText.isEmpty) {
      throw Exception('نصوص القرآن غير متوفرة للمطابقة');
    }

    // 1. تحديد السورة والآيات المستهدفة
    int targetSurah = hintSurah ?? 1;
    if (hintSurah == null && quranText.length > 1) {
      // وضع حر: البحث عن أفضل سورة تناسب النص المنطوق
      targetSurah = _detectBestSurah(asrWords, quranText);
    }

    final targetAyahsMap = quranText[targetSurah] ?? quranText.values.first;

    // 2. استخراج قائمة كلمات المصحف المستهدفة بالترتيب
    final List<_TargetWord> expectedWords = [];
    final sortedAyahNumbers = targetAyahsMap.keys.toList()..sort();

    for (final ayahNum in sortedAyahNumbers) {
      if (hintStartAyah != null && ayahNum < hintStartAyah) continue;
      if (hintEndAyah != null && ayahNum > hintEndAyah) continue;

      final ayahText = targetAyahsMap[ayahNum] ?? '';
      final words = ayahText
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();

      for (int i = 0; i < words.length; i++) {
        final w = words[i].trim();
        expectedWords.add(
          _TargetWord(
            surahNumber: targetSurah,
            ayahNumber: ayahNum,
            wordIndex: i,
            text: w,
            normalized: TextUtils.normalizeQuranText(w),
            phonetic: TextUtils.normalizePhonetic(w),
          ),
        );
      }
    }

    if (expectedWords.isEmpty) {
      throw Exception('لا توجد كلمات في النطاق القرآني المحدد');
    }

    // 3. تصفية كلمات ASR وتجهيزها
    final validAsrWords = asrWords
        .where((w) => TextUtils.normalizeQuranText(w.text).isNotEmpty)
        .toList();

    // 4. تنفيذ خوارزمية المحاذاة الشاملة (Needleman-Wunsch Global Alignment)
    final alignedMatches = _alignSequences(expectedWords, validAsrWords);

    // 5. حساب الثقة والتقييم الإجمالي
    double totalSim = 0.0;
    int evaluatedWordsCount = 0;
    for (final m in alignedMatches) {
      if (m.verdict != WordVerdict.skipped) {
        totalSim += m.similarity;
        evaluatedWordsCount++;
      }
    }
    final confidence = evaluatedWordsCount > 0
        ? (totalSim / evaluatedWordsCount)
        : 0.0;

    final firstAyah = expectedWords.first.ayahNumber;
    final lastAyah = expectedWords.last.ayahNumber;

    return MatchResult(
      surahNumber: targetSurah,
      surahName: '',
      startAyah: firstAyah,
      endAyah: lastAyah,
      matchedWords: alignedMatches,
      overallConfidence: confidence,
    );
  }

  /// خوارزمية المحاذاة الديناميكية (Dynamic Sequence Alignment)
  /// تضمن تغطية كل كلمة مستهدفة في المصحف وتحديد حالتها (صحيح، مقبول، خطأ، متجاوز)
  List<MatchedWord> _alignSequences(
    List<_TargetWord> expected,
    List<AsrWord> spoken,
  ) {
    final int n = expected.length;
    final int m = spoken.length;

    // إذا لم ينطق المستخدم أي كلمة، فجميع الكلمات تم تجاوزها (Skipped)
    if (m == 0) {
      return expected
          .map(
            (e) => MatchedWord(
              spokenWord: '',
              expectedWord: e.text,
              surahNumber: e.surahNumber,
              ayahNumber: e.ayahNumber,
              wordIndex: e.wordIndex,
              similarity: 0.0,
              verdict: WordVerdict.skipped,
            ),
          )
          .toList();
    }

    // مصفوفة البرمجة الديناميكية
    // dp[i][j] = أعلى درجة محاذاة للبادئة expected[0..i-1] مع spoken[0..j-1]
    final dp = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0.0));

    // عقوبة التخطي والإضافة
    const double gapPenaltyExpected = -1.0; // كلمة في المصحف لم تُقرأ
    const double gapPenaltySpoken = -0.6; // كلمة زائدة قالها المستخدم

    for (int i = 1; i <= n; i++) {
      dp[i][0] = dp[i - 1][0] + gapPenaltyExpected;
    }
    for (int j = 1; j <= m; j++) {
      dp[0][j] = dp[0][j - 1] + gapPenaltySpoken;
    }

    // حساب درجات التشابه ومصفوفة التكلفة
    for (int i = 1; i <= n; i++) {
      final expWord = expected[i - 1];
      for (int j = 1; j <= m; j++) {
        final spkWord = spoken[j - 1];

        final double sim = TextUtils.calculateSimilarity(
          spkWord.text,
          expWord.text,
        );

        // حساب وزن التطابق
        double matchScore;
        if (sim >= 0.85) {
          matchScore = 2.0 * sim; // مكافأة عالية للتطابق التام
        } else if (sim >= 0.60) {
          matchScore = 1.0 * sim; // مكافأة مقبولة
        } else if (sim >= 0.40) {
          matchScore = -0.2; // شبه تطابق
        } else {
          matchScore = -1.2; // كلمة مختلفة تماماً
        }

        final scoreMatch = dp[i - 1][j - 1] + matchScore;
        final scoreSkipExpected = dp[i - 1][j] + gapPenaltyExpected;
        final scoreExtraSpoken = dp[i][j - 1] + gapPenaltySpoken;

        dp[i][j] = [
          scoreMatch,
          scoreSkipExpected,
          scoreExtraSpoken,
        ].reduce((a, b) => a > b ? a : b);
      }
    }

    // التتبع العكسي (Traceback) لبناء قائمة المحاذاة النهائية
    int i = n;
    int j = m;

    final List<MatchedWord> result = [];

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final expWord = expected[i - 1];
        final spkWord = spoken[j - 1];
        final double sim = TextUtils.calculateSimilarity(
          spkWord.text,
          expWord.text,
        );

        double matchScore;
        if (sim >= 0.85) {
          matchScore = 2.0 * sim;
        } else if (sim >= 0.60) {
          matchScore = 1.0 * sim;
        } else if (sim >= 0.40) {
          matchScore = -0.2;
        } else {
          matchScore = -1.2;
        }

        final scoreMatch = dp[i - 1][j - 1] + matchScore;
        final scoreSkipExpected = dp[i - 1][j] + gapPenaltyExpected;

        // إذا كان المسار الأفضل هو المطابقة/الاستبدال
        if ((dp[i][j] - scoreMatch).abs() < 1e-4) {
          WordVerdict verdict;
          if (sim >= 0.70) {
            verdict = WordVerdict.correct;
          } else if (sim >= 0.45) {
            verdict = WordVerdict.acceptable;
          } else {
            verdict = WordVerdict.incorrect;
          }

          result.add(
            MatchedWord(
              spokenWord: spkWord.text,
              expectedWord: expWord.text,
              surahNumber: expWord.surahNumber,
              ayahNumber: expWord.ayahNumber,
              wordIndex: expWord.wordIndex,
              similarity: sim,
              verdict: verdict,
              startMs: spkWord.startMs,
              endMs: spkWord.endMs,
            ),
          );
          i--;
          j--;
          continue;
        } else if ((dp[i][j] - scoreSkipExpected).abs() < 1e-4) {
          // كلمة في المصحف تم تجاوزها
          result.add(
            MatchedWord(
              spokenWord: '',
              expectedWord: expWord.text,
              surahNumber: expWord.surahNumber,
              ayahNumber: expWord.ayahNumber,
              wordIndex: expWord.wordIndex,
              similarity: 0.0,
              verdict: WordVerdict.skipped,
            ),
          );
          i--;
          continue;
        } else {
          // كلمة زائدة قالها المستخدم
          j--;
          continue;
        }
      } else if (i > 0) {
        // بقية كلمات المصحف تم تجاوزها
        final expWord = expected[i - 1];
        result.add(
          MatchedWord(
            spokenWord: '',
            expectedWord: expWord.text,
            surahNumber: expWord.surahNumber,
            ayahNumber: expWord.ayahNumber,
            wordIndex: expWord.wordIndex,
            similarity: 0.0,
            verdict: WordVerdict.skipped,
          ),
        );
        i--;
      } else if (j > 0) {
        j--;
      }
    }

    // عكس النتيجة لأننا بنيناها بالتتبع العكسي من النهاية للبداية
    return result.reversed.toList();
  }

  /// اكتشاف السورة الأقرب للنص المنطوق في الوضع الحر
  int _detectBestSurah(
    List<AsrWord> spoken,
    Map<int, Map<int, String>> allQuran,
  ) {
    if (spoken.isEmpty) return 1;

    final spokenSample = spoken
        .take(8)
        .map((w) => TextUtils.normalizePhonetic(w.text))
        .join(' ');

    int bestSurah = 1;
    double bestScore = -1.0;

    // حلقة for مع خروج مبكر حقيقي (forEach لا يسمح بكسر الحلقة)
    for (final entry in allQuran.entries) {
      final firstAyahs = entry.value.values.take(3).join(' ');
      final normQuran = TextUtils.normalizePhonetic(firstAyahs);

      if (normQuran.contains(spokenSample)) {
        // تطابق كامل - توقف فوراً عن فحص بقية السور
        return entry.key;
      }

      // partial match by words
      int matches = 0;
      for (final spk in spoken.take(5)) {
        final normSpk = TextUtils.normalizePhonetic(spk.text);
        if (normSpk.length >= 3 && normQuran.contains(normSpk)) {
          matches++;
        }
      }

      final score = matches / (spoken.length.clamp(1, 5));
      if (score > bestScore) {
        bestScore = score;
        bestSurah = entry.key;
      }
    }
    return bestSurah;
  }
}
