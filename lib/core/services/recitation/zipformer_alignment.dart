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
    this.activeWordIndex,
    this.blockedWord,
  });

  final QuranVersePhonemes verse;
  final List<WordMatchEvent> words;
  final bool isComplete;
  final int consumedPhonemes;

  /// Last matched canonical word during a replay of the active ayah.
  final int? activeWordIndex;

  /// Confirmed word awaiting correction in strict practice.
  final WordMatchEvent? blockedWord;

  ZipformerVerseAlignment _atReplayWord(int? wordIndex) => wordIndex == null
      ? this
      : ZipformerVerseAlignment(
          verse: verse,
          words: words,
          isComplete: isComplete,
          consumedPhonemes: consumedPhonemes,
          activeWordIndex: wordIndex,
          blockedWord: blockedWord,
        );
}

/// Creates independent alignment state for each live recording.
class ZipformerAlignment {
  const ZipformerAlignment(this._repository);

  final RecitationPhonemeRepository _repository;

  ZipformerAlignmentSession newSession({
    int? surah,
    int? startAyah,
    int? endAyah,
    bool stopOnConfirmedError = false,
  }) => ZipformerAlignmentSession._(
    _repository,
    surah: surah,
    startAyah: startAyah,
    endAyah: endAyah,
    stopOnConfirmedError: stopOnConfirmedError,
  );

  List<ZipformerVerseAlignment> align(
    String rawPhonemes, {
    int? surah,
    int? startAyah,
    int? endAyah,
    bool isFinal = false,
    bool stopOnConfirmedError = false,
  }) => newSession(
    surah: surah,
    startAyah: startAyah,
    endAyah: endAyah,
    stopOnConfirmedError: stopOnConfirmedError,
  ).update(rawPhonemes, isFinal: isFinal);
}

class ZipformerAlignmentSession {
  ZipformerAlignmentSession._(
    this._repository, {
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    required this.stopOnConfirmedError,
  });

  final RecitationPhonemeRepository _repository;
  final int? surah;
  final int? startAyah;
  final int? endAyah;
  final bool stopOnConfirmedError;
  final _confirmed = <ZipformerVerseAlignment>[];
  QuranVersePhonemes? _currentVerse;
  var _offset = 0;
  var _protectedPrefixEnd = 0;
  var _rawPhonemes = '';
  var _normalized = '';

  List<ZipformerVerseAlignment> update(
    String rawPhonemes, {
    bool isFinal = false,
  }) {
    final normalized = _normalize(rawPhonemes);
    if (normalized.trim().isEmpty) return const [];

    final selected = surah != null;
    if (selected &&
        (startAyah == null || endAyah == null || startAyah! > endAyah!)) {
      return const [];
    }
    final beginning = _currentVerse == null
        ? _findBeginning(normalized, isFinal: isFinal)
        : null;
    var verse = _currentVerse ?? beginning?.$1;
    var offset = beginning?.$2 ?? _offset;
    var followsVerse = _confirmed.isNotEmpty;
    while (verse != null && offset < normalized.length) {
      final matcher = PhonemeWordMatcher(referenceVerse: verse);
      final nextVerse = _followingVerse(verse);
      var words = matcher.processNormalizedPhonemes(
        normalized,
        startOffset: offset,
        followsVerse: followsVerse,
        allowReplay: true,
        followingVerse: nextVerse,
        stopOnConfirmedError: stopOnConfirmedError,
      );
      if (_currentVerse == null) {
        final evidence = words.where(_isMatched).toList();
        if (!selected &&
            evidence.length < 2 &&
            !(matcher.isCompleted && evidence.isNotEmpty)) {
          return const [];
        }
        if (evidence.isNotEmpty) {
          _currentVerse = verse;
          _offset = offset;
          _protectedPrefixEnd = evidence.first.phonemeEnd ?? offset;
        }
      }

      final unresolvedTail = matcher.unresolvedTailWordCount;
      final matchedOffset = offset + matcher.consumedPhonemes;
      final following =
          matcher.blockedWord == null &&
              !matcher.awaitingReplayEvidence &&
              matchedOffset < normalized.length &&
              matcher.consumedPhonemes > 0 &&
              (matcher.isCompleted || unresolvedTail > 0)
          ? nextVerse
          : null;
      final recoveredOffset = following != null
          ? matcher.findFollowingVerseOffset(
              normalized,
              startOffset: offset,
              following: following,
            )
          : null;
      if (unresolvedTail > 0 && recoveredOffset != null) {
        words = matcher.endAtFollowingVerse(
          normalized,
          trailingStart: matchedOffset,
          followingOffset: recoveredOffset,
          following: following!,
        );
      } else if (unresolvedTail == 1 &&
          isFinal &&
          matcher.blockedWord == null &&
          words.last.status == WordRecitationStatus.current) {
        words = [...words]..[words.length - 1] = words.last.asUnconfirmed();
      }
      final completed = matcher.isCompleted || recoveredOffset != null;
      final nextOffset = recoveredOffset ?? matchedOffset;
      final current = ZipformerVerseAlignment(
        verse: verse,
        words: words,
        isComplete: completed,
        consumedPhonemes: nextOffset - offset,
        blockedWord: matcher.blockedWord,
      );

      if (following == null || !completed || nextOffset == offset) {
        return [
          ..._confirmed,
          current._atReplayWord(matcher.lastReplayWordIndex),
        ];
      }
      final probe = PhonemeWordMatcher(referenceVerse: following);
      final followingWords = probe.processNormalizedPhonemes(
        normalized,
        startOffset: nextOffset,
        followsVerse: true,
      );
      if (!followingWords.any(_isMatched)) {
        final skip = matcher.isCompleted
            ? _findOmittedVerse(
                normalized,
                matcher: matcher,
                verse: verse,
                following: following,
                startOffset: offset,
              )
            : null;
        if (skip == null) {
          return [
            ..._confirmed,
            current._atReplayWord(matcher.lastReplayWordIndex),
            ZipformerVerseAlignment(
              verse: following,
              words: followingWords,
              isComplete: false,
              consumedPhonemes: 0,
            ),
          ];
        }
        final (resumedVerse, resumeOffset) = skip;
        _confirmed
          ..add(current)
          ..add(_omittedVerse(following));
        _currentVerse = resumedVerse;
        _offset = resumeOffset;
        _protectedPrefixEnd = resumeOffset;
        offset = resumeOffset;
        verse = resumedVerse;
        followsVerse = true;
        continue;
      }
      _confirmed.add(current);
      _currentVerse = following;
      _offset = nextOffset;
      _protectedPrefixEnd = nextOffset;
      offset = nextOffset;
      verse = following;
      followsVerse = true;
    }
    return List.of(_confirmed);
  }

  static bool _isMatched(WordMatchEvent word) =>
      word.status == WordRecitationStatus.matched ||
      word.status == WordRecitationStatus.corrected;

  String _normalize(String raw) {
    if (raw == _rawPhonemes) return _normalized;
    final String normalized;
    if (raw.startsWith(_rawPhonemes)) {
      normalized =
          _normalized +
          PhonemeUtils.cleanPhonemes(raw.substring(_rawPhonemes.length));
    } else {
      normalized = PhonemeUtils.cleanPhonemes(raw);
      if (!normalized.startsWith(
        _normalized.substring(0, _protectedPrefixEnd),
      )) {
        _confirmed.clear();
        _currentVerse = null;
        _offset = 0;
        _protectedPrefixEnd = 0;
      }
    }
    _rawPhonemes = raw;
    _normalized = normalized;
    return normalized;
  }

  (QuranVersePhonemes, int)? _findBeginning(
    String input, {
    required bool isFinal,
  }) {
    final beginning = _skipWhitespace(input, 0);
    final afterRefuge =
        _findOpeningPhrase(input, beginning, _refugePhrases) ?? beginning;
    final firstVerse = _repository.getVersePhonemes(1, 1);
    final afterBasmala = _findOpeningPhrase(input, afterRefuge, [
      if (firstVerse != null) firstVerse.ayaPhoneme,
      'بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم',
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
    ]);
    if (surah case final selectedSurah?) {
      final verse = _repository.getVersePhonemes(selectedSurah, startAyah!);
      if (verse == null) return null;
      final offset = verse.verseKey == '1:1'
          ? afterRefuge
          : afterBasmala ?? afterRefuge;
      return (verse, offset);
    }

    final offset = afterBasmala ?? afterRefuge;
    final detected = _repository.findBestMatchingVerse(input.substring(offset));
    // In free mode a basmala followed by Al-Fatihah 1:2 belongs to the
    // reading. An isolated basmala is undecidable while the stream is open.
    if (afterBasmala != null &&
        firstVerse != null &&
        (detected?.verseKey == '1:2' || (isFinal && offset == input.length))) {
      return (firstVerse, afterRefuge);
    }
    return detected == null ? null : (detected, offset);
  }

  static const _refugePhrases = [
    'ءَعُۥۥذُبِللَااهِمِنَششَيطَاانِررَجِۦۦۦۦم',
    'أعوذ بالله من الشيطان الرجيم',
  ];

  static int? _findOpeningPhrase(
    String input,
    int offset,
    List<String> phrases,
  ) {
    for (final phrase in phrases) {
      final expected = _openingCodes(phrase).map((entry) => entry.$1).toList();
      if (expected.isEmpty) continue;
      var matched = 0;
      for (final (code, end) in _openingCodes(input, offset: offset)) {
        if (code != expected[matched]) break;
        matched++;
        if (matched == expected.length) return _skipOpeningMarks(input, end);
      }
    }
    return null;
  }

  static Iterable<(int, int)> _openingCodes(
    String text, {
    int offset = 0,
  }) sync* {
    int? previous;
    // Prefix recognition is bounded and limited to the two named phrases.
    for (var i = offset; i < text.length && i - offset < 140; i++) {
      final raw = text.codeUnitAt(i);
      if (_isOpeningMark(raw)) continue;
      final code = switch (raw) {
        0x0623 || 0x0624 || 0x0625 || 0x0626 => 0x0621,
        0x0671 || 0x0649 => 0x0627,
        0x06e5 => 0x0648,
        0x06e6 => 0x064a,
        _ => raw,
      };
      if (code != previous) yield (code, i + 1);
      previous = code;
    }
  }

  static bool _isOpeningMark(int code) =>
      code <= 0x20 ||
      (code >= 0x0610 && code <= 0x061a) ||
      (code >= 0x064b && code <= 0x065f) ||
      code == 0x0670 ||
      PhonemeUtils.isZeroCostMarker(code);

  static int _skipOpeningMarks(String text, int offset) {
    while (offset < text.length && _isOpeningMark(text.codeUnitAt(offset))) {
      offset++;
    }
    return offset;
  }

  static int _skipWhitespace(String text, int offset) {
    while (offset < text.length && text.codeUnitAt(offset) <= 0x20) {
      offset++;
    }
    return offset;
  }

  (QuranVersePhonemes, int)? _findOmittedVerse(
    String input, {
    required PhonemeWordMatcher matcher,
    required QuranVersePhonemes verse,
    required QuranVersePhonemes following,
    required int startOffset,
  }) {
    final resumed = _followingVerse(following);
    final surahKey = verse.verseKey.split(':').first;
    if (resumed == null ||
        !following.verseKey.startsWith('$surahKey:') ||
        !resumed.verseKey.startsWith('$surahKey:')) {
      return null;
    }
    final offset = matcher.findFollowingVerseOffset(
      input,
      startOffset: startOffset,
      following: resumed,
      allowExactBoundary: true,
      minimumWords: 3,
    );
    if (offset == null) return null;
    final competing = PhonemeWordMatcher(referenceVerse: following)
        .processNormalizedPhonemes(input, startOffset: offset);
    // A real opening in the immediately following ayah takes priority.
    if (competing.any(_isMatched)) return null;
    return (resumed, offset);
  }

  ZipformerVerseAlignment _omittedVerse(QuranVersePhonemes verse) =>
      ZipformerVerseAlignment(
        verse: verse,
        words: [
          WordMatchEvent(
            wordIndex: 0,
            wordText: verse.ayaText,
            referencePhonemes: verse.ayaPhoneme,
            recognizedPhonemes: '',
            similarity: 0,
            status: WordRecitationStatus.omittedVerse,
          ),
        ],
        isComplete: false,
        consumedPhonemes: 0,
      );

  QuranVersePhonemes? _followingVerse(QuranVersePhonemes verse) {
    final [surahText, ayahText] = verse.verseKey.split(':');
    final currentSurah = int.parse(surahText);
    final ayah = int.parse(ayahText);
    if (endAyah != null && ayah >= endAyah!) return null;
    final next = _repository.getVersePhonemes(currentSurah, ayah + 1);
    if (next != null || surah != null) return next;
    return _repository.getVersePhonemes(currentSurah + 1, 1);
  }
}
