// lib/core/services/recitation/phoneme_matcher.dart
// ═══════════════════════════════════════════════════════════════════════════════
// محرك المحاذاة والمطابقة اللحظية للكلمات القرآنية (Phoneme Word Matcher)
//
// مقتبس ومطور استناداً إلى خوارزميات حزمة recite_quran (v1.0.5)
// المرخصة كوقف لله تعالى (No-Profit / 100% Free / لوجه الله تعالى).
// ═══════════════════════════════════════════════════════════════════════════════

import '../../utils/phoneme_utils.dart';
import 'recitation_models.dart';

class PhonemeWordMatcher {
  final QuranVersePhonemes referenceVerse;
  final List<String> _wordsText;
  final List<WordMatchEvent> _wordStatuses = [];
  int _activeWordIndex = 0;

  PhonemeWordMatcher({required this.referenceVerse})
      : _wordsText = referenceVerse.ayaText.split(' ') {
    _initStatuses();
  }

  void _initStatuses() {
    _wordStatuses.clear();
    final count = referenceVerse.ayaPhonemesList.length;
    for (int i = 0; i < count; i++) {
      final wordText = i < _wordsText.length ? _wordsText[i] : '';
      final refPh = referenceVerse.ayaPhonemesList[i];
      _wordStatuses.add(
        WordMatchEvent(
          wordIndex: i,
          wordText: wordText,
          referencePhonemes: refPh,
          recognizedPhonemes: '',
          similarity: 0.0,
          status: i == 0 ? WordRecitationStatus.current : WordRecitationStatus.unspoken,
        ),
      );
    }
  }

  List<WordMatchEvent> get wordStatuses => List.unmodifiable(_wordStatuses);
  int get activeWordIndex => _activeWordIndex;
  bool get isCompleted => _activeWordIndex >= _wordStatuses.length;

  /// معالجة سيل الرموز الصوتية القادمة من محرك ASR وتحديث حالة الكلمات اللحظية.
  List<WordMatchEvent> processLivePhonemes(String rawAsrPhonemes) {
    if (rawAsrPhonemes.isEmpty || _wordStatuses.isEmpty) {
      return wordStatuses;
    }

    final cleanAsr = PhonemeUtils.cleanPhonemes(rawAsrPhonemes);
    if (cleanAsr.isEmpty) return wordStatuses;

    int consumedPhonemes = 0;

    for (int i = 0; i < _wordStatuses.length; i++) {
      final refPh = PhonemeUtils.cleanPhonemes(_wordStatuses[i].referencePhonemes);
      if (refPh.isEmpty) continue;

      final remainingAsrLen = cleanAsr.length - consumedPhonemes;
      if (remainingAsrLen <= 0) break;

      // نافذة البحث التقريبية بطول الكلمة المرجعية مع هامش سماح
      final windowLen = (refPh.length * 1.5).ceil().clamp(refPh.length, remainingAsrLen);
      final asrSlice = cleanAsr.substring(
        consumedPhonemes,
        consumedPhonemes + windowLen,
      );

      final similarity = PhonemeUtils.similarityScore(asrSlice, refPh);

      if (similarity >= 0.55) {
        // تم التعرف على الكلمة بنجاح
        _wordStatuses[i] = WordMatchEvent(
          wordIndex: i,
          wordText: _wordStatuses[i].wordText,
          referencePhonemes: _wordStatuses[i].referencePhonemes,
          recognizedPhonemes: asrSlice,
          similarity: similarity,
          status: WordRecitationStatus.matched,
        );
        consumedPhonemes += refPh.length;
        _activeWordIndex = i + 1;
      } else {
        // فحص هل تجاوز القارئ الكلمة وقفز للكلمة التالية (Omission Detection)
        if (i + 1 < _wordStatuses.length) {
          final nextRefPh = PhonemeUtils.cleanPhonemes(_wordStatuses[i + 1].referencePhonemes);
          final nextSimilarity = PhonemeUtils.similarityScore(asrSlice, nextRefPh);
          if (nextSimilarity >= 0.65) {
            // الكلمة الحالية سقطت سهواً
            _wordStatuses[i] = WordMatchEvent(
              wordIndex: i,
              wordText: _wordStatuses[i].wordText,
              referencePhonemes: _wordStatuses[i].referencePhonemes,
              recognizedPhonemes: '',
              similarity: 0.0,
              status: WordRecitationStatus.omitted,
            );
            _activeWordIndex = i + 1;
            continue;
          }
        }

        // الكلمة لا تزال قيد القراءة
        _wordStatuses[i] = WordMatchEvent(
          wordIndex: i,
          wordText: _wordStatuses[i].wordText,
          referencePhonemes: _wordStatuses[i].referencePhonemes,
          recognizedPhonemes: asrSlice,
          similarity: similarity,
          status: WordRecitationStatus.current,
        );
        _activeWordIndex = i;
        break;
      }
    }

    return wordStatuses;
  }
}
