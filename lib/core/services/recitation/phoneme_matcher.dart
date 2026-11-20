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
  PhonemeWordMatcher({required this.referenceVerse})
    : _wordsText = referenceVerse.ayaText.trim().split(RegExp(r'\s+')),
      _references = referenceVerse.ayaPhonemesList
          .map(PhonemeUtils.cleanPhonemes)
          .toList() {
    _reset();
  }

  final QuranVersePhonemes referenceVerse;
  final List<String> _wordsText;
  final List<String> _references;
  final List<WordMatchEvent> _wordStatuses = [];
  int _activeWordIndex = 0;
  int _consumedPhonemes = 0;

  void _reset() {
    _activeWordIndex = 0;
    _consumedPhonemes = 0;
    _wordStatuses.clear();
    for (int i = 0; i < _references.length; i++) {
      _wordStatuses.add(
        _event(
          i,
          i == 0 ? WordRecitationStatus.current : WordRecitationStatus.unspoken,
        ),
      );
    }
  }

  WordMatchEvent _event(
    int index,
    WordRecitationStatus status, {
    String recognized = '',
    double similarity = 0,
  }) {
    return WordMatchEvent(
      wordIndex: index,
      wordText: index < _wordsText.length ? _wordsText[index] : '',
      referencePhonemes: referenceVerse.ayaPhonemesList[index],
      recognizedPhonemes: recognized,
      similarity: similarity,
      status: status,
    );
  }

  List<WordMatchEvent> get wordStatuses => List.unmodifiable(_wordStatuses);
  int get activeWordIndex => _activeWordIndex;

  /// Code units consumed after normalization, relative to the start offset.
  int get consumedPhonemes => _consumedPhonemes;
  bool get isCompleted => _activeWordIndex >= _wordStatuses.length;

  /// A decoder may revise or shorten its cumulative hypothesis. Re-evaluate
  /// from the start and clear conclusions no longer supported by its input.
  List<WordMatchEvent> processLivePhonemes(String rawAsrPhonemes) {
    return processNormalizedPhonemes(
      PhonemeUtils.cleanPhonemes(rawAsrPhonemes),
    );
  }

  List<WordMatchEvent> processNormalizedPhonemes(
    String phonemes, {
    int startOffset = 0,
  }) {
    RangeError.checkValueInInterval(startOffset, 0, phonemes.length);
    _reset();
    var offset = startOffset;
    for (var i = 0; i < _references.length; i++) {
      _activeWordIndex = i;
      final reference = _references[i];
      if (reference.isEmpty || offset == phonemes.length) {
        _wordStatuses[i] = _event(i, WordRecitationStatus.current);
        break;
      }

      if (_matchesAt(phonemes, offset, reference)) {
        _wordStatuses[i] = _event(
          i,
          WordRecitationStatus.matched,
          recognized: phonemes.substring(offset, offset + reference.length),
          similarity: 1,
        );
        offset += reference.length;
        _activeWordIndex = i + 1;
        continue;
      }

      final remaining = phonemes.length - offset;
      if (remaining < reference.length &&
          _matchesAt(phonemes, offset, reference.substring(0, remaining))) {
        _wordStatuses[i] = _event(
          i,
          WordRecitationStatus.current,
          recognized: phonemes.substring(offset),
        );
        break;
      }
      final next = i + 1 < _references.length ? _references[i + 1] : '';
      if (next.length >= 4 && _matchesAt(phonemes, offset, next)) {
        _wordStatuses[i] = _event(i, WordRecitationStatus.omitted);
        _activeWordIndex = i + 1;
        continue;
      }

      // Two complete following words anchor a substitution. A short or
      // ambiguous span remains pending because it may be a partial word.
      final replacementEnd = _confirmedReplacementEnd(phonemes, offset, i);
      if (replacementEnd != null) {
        final heard = phonemes.substring(offset, replacementEnd);
        _wordStatuses[i] = _event(
          i,
          WordRecitationStatus.incorrect,
          recognized: heard,
          similarity: PhonemeUtils.similarityScore(heard, reference),
        );
        offset = replacementEnd;
        _activeWordIndex = i + 1;
        continue;
      }

      _wordStatuses[i] = _event(i, WordRecitationStatus.current);
      break;
    }

    _consumedPhonemes = offset - startOffset;
    return wordStatuses;
  }

  int? _confirmedReplacementEnd(String phonemes, int offset, int wordIndex) {
    if (wordIndex + 2 >= _references.length) return null;
    final next = _references[wordIndex + 1];
    final following = _references[wordIndex + 2];
    if (next.length < 3 || following.length < 3) return null;
    final expectedLength = _references[wordIndex].length;
    int? confirmedEnd;
    for (
      var end = offset + expectedLength;
      end <= offset + expectedLength + 2;
      end++
    ) {
      if (_matchesAt(phonemes, end, next) &&
          _matchesAt(phonemes, end + next.length, following)) {
        if (confirmedEnd != null) return null;
        confirmedEnd = end;
      }
    }
    return confirmedEnd;
  }

  static bool _matchesAt(String input, int offset, String reference) {
    if (reference.isEmpty || offset + reference.length > input.length) {
      return false;
    }
    for (var i = 0; i < reference.length; i++) {
      if (!PhonemeUtils.isEquivalentGlyph(
        input.codeUnitAt(offset + i),
        reference.codeUnitAt(i),
      )) {
        return false;
      }
    }
    return true;
  }
}
