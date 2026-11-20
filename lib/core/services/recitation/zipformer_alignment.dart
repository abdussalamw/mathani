import '../../utils/phoneme_utils.dart';
import 'phoneme_matcher.dart';
import 'recitation_models.dart';
import 'recitation_phoneme_repository.dart';

class ZipformerVerseAlignment {
  const ZipformerVerseAlignment({
    required this.verse,
    required this.words,
    required this.isComplete,
    required this.consumedPhonemes,
  });

  final QuranVersePhonemes verse;
  final List<WordMatchEvent> words;
  final bool isComplete;
  final int consumedPhonemes;
}

/// Aligns each cumulative CTC hypothesis against a selected or detected range.
class ZipformerAlignment {
  const ZipformerAlignment(this._repository);

  final RecitationPhonemeRepository _repository;

  List<ZipformerVerseAlignment> align(
    String rawPhonemes, {
    int? surah,
    int? startAyah,
    int? endAyah,
  }) {
    final normalized = PhonemeUtils.cleanPhonemes(rawPhonemes);
    if (normalized.trim().isEmpty) return const [];

    final selected = surah != null;
    if (selected &&
        (startAyah == null || endAyah == null || startAyah > endAyah)) {
      return const [];
    }
    var verse = selected
        ? _repository.getVersePhonemes(surah, startAyah!)
        : _repository.findBestMatchingVerse(normalized);
    final verses = <ZipformerVerseAlignment>[];
    var offset = 0;
    while (verse != null && offset < normalized.length) {
      final matcher = PhonemeWordMatcher(referenceVerse: verse);
      final words = matcher.processNormalizedPhonemes(
        normalized,
        startOffset: offset,
      );
      verses.add(
        ZipformerVerseAlignment(
          verse: verse,
          words: words,
          isComplete: matcher.isCompleted,
          consumedPhonemes: matcher.consumedPhonemes,
        ),
      );
      if (!matcher.isCompleted || matcher.consumedPhonemes == 0) break;
      offset += matcher.consumedPhonemes;
      if (offset == normalized.length) break;

      final [surahText, ayahText] = verse.verseKey.split(':');
      final surahNumber = int.parse(surahText);
      final ayahNumber = int.parse(ayahText);
      if (selected && ayahNumber >= endAyah!) break;
      verse = _repository.getVersePhonemes(surahNumber, ayahNumber + 1);
      if (!selected && verse == null) {
        verse = _repository.getVersePhonemes(surahNumber + 1, 1);
      }
    }
    return verses;
  }
}
