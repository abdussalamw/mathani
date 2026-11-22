// lib/core/services/recitation/phoneme_matcher.dart
// ═══════════════════════════════════════════════════════════════════════════════
// محرك المحاذاة والمطابقة اللحظية للكلمات القرآنية (Phoneme Word Matcher)
//
// مقتبس ومطور استناداً إلى خوارزميات حزمة recite_quran (v1.0.5)
// المرخصة كوقف لله تعالى (No-Profit / 100% Free / لوجه الله تعالى).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

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
  final Map<int, WordMatchEvent> _addedWords = {};
  int _activeWordIndex = 0;
  int _consumedPhonemes = 0;
  int? _lastReplayWordIndex;
  bool _awaitingReplayEvidence = false;
  WordMatchEvent? _blockedWord;

  void _reset() {
    _activeWordIndex = 0;
    _consumedPhonemes = 0;
    _lastReplayWordIndex = null;
    _awaitingReplayEvidence = false;
    _blockedWord = null;
    _wordStatuses.clear();
    _addedWords.clear();
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
    int? phonemeStart,
    int? phonemeEnd,
  }) {
    return WordMatchEvent(
      wordIndex: index,
      wordText: index < _wordsText.length ? _wordsText[index] : '',
      referencePhonemes: referenceVerse.ayaPhonemesList[index],
      recognizedPhonemes: recognized,
      similarity: similarity,
      status: status,
      phonemeStart: phonemeStart,
      phonemeEnd: phonemeEnd,
    );
  }

  List<WordMatchEvent> get wordStatuses => List.unmodifiable([
    for (final word in _wordStatuses) ...[?_addedWords[word.wordIndex], word],
  ]);
  int get activeWordIndex => _activeWordIndex;
  int? get lastReplayWordIndex => _lastReplayWordIndex;
  bool get awaitingReplayEvidence => _awaitingReplayEvidence;
  WordMatchEvent? get blockedWord => _blockedWord;

  /// Code units consumed after normalization, relative to the start offset.
  int get consumedPhonemes => _consumedPhonemes;
  bool get isCompleted => _activeWordIndex >= _wordStatuses.length;

  int get unresolvedTailWordCount {
    final remaining = _references.length - _activeWordIndex;
    if (_activeWordIndex == 0 ||
        remaining < 1 ||
        remaining > 2 ||
        !_wordStatuses.any(
          (word) =>
              word.status == WordRecitationStatus.matched ||
              word.status == WordRecitationStatus.corrected,
        )) {
      return 0;
    }
    return remaining;
  }

  /// Find a unique opening after the unresolved final word or its retries.
  /// If the final word matched, only exact repetitions may be discarded.
  int? findFollowingVerseOffset(
    String phonemes, {
    required int startOffset,
    required QuranVersePhonemes following,
    bool allowExactBoundary = false,
    int? minimumWords,
  }) {
    if (_references.isEmpty) return null;
    final first = startOffset + _consumedPhonemes;
    final expected = _references.last;
    final skipOnlyRepeats = isCompleted;
    if (skipOnlyRepeats &&
        (!allowExactBoundary && !_matchesAt(phonemes, first, expected) ||
            expected.isEmpty)) {
      return null;
    }

    final minimum = minimumWords ?? (unresolvedTailWordCount == 2 ? 3 : 2);
    final opening = following.ayaPhonemesList
        .take(3)
        .map(PhonemeUtils.cleanPhonemes)
        .toList();
    if (opening.length < minimum ||
        opening.take(minimum).any((word) => word.isEmpty)) {
      return null;
    }
    var anchor = opening.take(minimum).join();
    var anchorWords = minimum;
    if (anchor.length < 8 && minimum == 2 && opening.length == 3) {
      anchor += opening[2];
      anchorWords++;
    }
    if (anchor.length < (minimumWords == 3 ? 14 : 8)) return null;

    // Allow nearby retries with a fixed ceiling on how much audio can be skipped.
    final tailLength = unresolvedTailWordCount == 2
        ? _references[_references.length - 2].length + expected.length
        : expected.length;
    final retrySpan = math.min(48, tailLength * 4 + 4);
    final last = math.min(first + retrySpan, phonemes.length - anchor.length);
    final step = skipOnlyRepeats ? expected.length : 1;
    var candidates = <int>[];
    for (var offset = first; offset <= last; offset += step) {
      if (skipOnlyRepeats &&
          offset > first &&
          !_matchesAt(phonemes, offset - step, expected)) {
        break;
      }
      if (_matchesAt(phonemes, offset, anchor)) candidates.add(offset);
    }

    // The verse itself can repeat its opening. Favor the position supported
    // by more consecutive words when the short opening matches twice.
    var matchedLength = anchor.length;
    for (final rawWord in following.ayaPhonemesList.skip(anchorWords)) {
      if (candidates.length < 2) break;
      final word = PhonemeUtils.cleanPhonemes(rawWord);
      final extended = candidates
          .where((offset) => _matchesAt(phonemes, offset + matchedLength, word))
          .toList();
      if (extended.isEmpty) break;
      candidates = extended;
      matchedLength += word.length;
    }
    return candidates.length == 1 ? candidates.single : null;
  }

  List<WordMatchEvent> endAtFollowingVerse(
    String phonemes, {
    required int trailingStart,
    required int followingOffset,
    required QuranVersePhonemes following,
  }) {
    if (unresolvedTailWordCount == 1 && followingOffset > trailingStart) {
      final index = _activeWordIndex;
      final heard = phonemes.substring(trailingStart, followingOffset);
      if (_matchesEndingVariant(heard, following)) {
        _recordWord(
          _event(
            index,
            WordRecitationStatus.matched,
            recognized: heard,
            similarity: 1,
            phonemeStart: trailingStart,
            phonemeEnd: followingOffset,
          ),
        );
        return wordStatuses;
      }
    }
    return [
      for (final word in wordStatuses)
        word.wordIndex >= _activeWordIndex &&
                (word.status == WordRecitationStatus.current ||
                    word.status == WordRecitationStatus.unspoken)
            ? word.asUnconfirmed()
            : word,
    ];
  }

  bool _matchesEndingVariant(String heard, QuranVersePhonemes following) {
    final canonical = _wordsText.last.replaceAll(
      RegExp(r'[\u0610-\u061a\u06d6-\u06ed]'),
      '',
    );
    final expected = _references.last;
    final followingStart = following.ayaPhonemesList.first;
    if (RegExp(r'\u064b[اى]?$').hasMatch(canonical) &&
        expected.endsWith('اا') &&
        followingStart.isNotEmpty &&
        'ءهعحغخ'.contains(followingStart[0])) {
      final joined = '${expected.substring(0, expected.length - 2)}ن';
      if (heard.length == joined.length && _matchesAt(heard, 0, joined)) {
        return true;
      }
    }
    if (canonical.isEmpty) return false;
    final vowel = canonical[canonical.length - 1];
    if (!'َُِ'.contains(vowel)) return false;
    final variant = expected.endsWith(vowel)
        ? expected.substring(0, expected.length - 1)
        : expected + vowel;
    return heard.length == variant.length && _matchesAt(heard, 0, variant);
  }

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
    bool followsVerse = false,
    bool allowReplay = false,
    QuranVersePhonemes? followingVerse,
    bool stopOnConfirmedError = false,
  }) {
    RangeError.checkValueInInterval(startOffset, 0, phonemes.length);
    _reset();
    var offset = startOffset;
    for (var i = 0; i <= _references.length; i++) {
      _activeWordIndex = i;
      final atEnd = i == _references.length;
      final reference = atEnd ? '' : _references[i];

      if (_matchesAt(phonemes, offset, reference)) {
        _recordWord(
          _event(
            i,
            WordRecitationStatus.matched,
            recognized: phonemes.substring(offset, offset + reference.length),
            similarity: 1,
            phonemeStart: offset,
            phonemeEnd: offset + reference.length,
          ),
        );
        offset += reference.length;
        _activeWordIndex = i + 1;
        continue;
      }

      if (allowReplay && i > 0 && offset < phonemes.length) {
        final replay = _findReplay(
          phonemes,
          offset,
          i,
          following: followingVerse,
        );
        if (replay != null) {
          final restart = replay.wordIndex;
          if (restart == null) {
            _awaitingReplayEvidence = true;
            if (!atEnd) _recordWord(_event(i, WordRecitationStatus.current));
            break;
          }
          if (!atEnd && replay.offset > offset) {
            _recordInterruptedWord(phonemes, offset, replay.offset, i);
          }
          _lastReplayWordIndex = restart;
          offset = replay.offset;
          i = restart - 1;
          continue;
        }
      }
      if (atEnd) break;
      if (reference.isEmpty || offset == phonemes.length) {
        _recordWord(_event(i, WordRecitationStatus.current));
        break;
      }

      final remaining = phonemes.length - offset;
      if (remaining < reference.length &&
          _matchesAt(phonemes, offset, reference.substring(0, remaining))) {
        _recordWord(
          _event(
            i,
            WordRecitationStatus.current,
            recognized: phonemes.substring(offset),
            phonemeStart: offset,
            phonemeEnd: phonemes.length,
          ),
        );
        break;
      }
      final recovered = _recoverInVerse(phonemes, offset, i);
      if (recovered != null) {
        final (found, status, extra) = recovered;
        final recorded = _recordWord(
          _event(
            i,
            status,
            recognized: phonemes.substring(found, found + reference.length),
            similarity: 1,
            phonemeStart: found,
            phonemeEnd: found + reference.length,
          ),
        );
        if (extra != null && recorded) _addedWords[i] = extra;
        offset = found + reference.length;
        _activeWordIndex = i + 1;
        continue;
      }
      final next = i + 1 < _references.length ? _references[i + 1] : '';
      final atVerseBoundary = followsVerse && i == 0;
      final omitted = next.length >= 4 && _matchesAt(phonemes, offset, next);
      // Two complete following words locate the substitution. At an ayah
      // boundary this locates the reading even when the opening word is unclear.
      final followingOffset = omitted
          ? offset
          : _confirmedReplacementEnd(
              phonemes,
              offset,
              i,
              allowShorterSpan: atVerseBoundary,
            );
      if (followingOffset != null) {
        // A short word shared with another phrase gives weak evidence on its
        // own. Wait for the next word when it belongs to this ayah.
        if (stopOnConfirmedError &&
            !atVerseBoundary &&
            omitted &&
            i + 2 < _references.length &&
            !_matchesAt(phonemes, offset + next.length, _references[i + 2])) {
          _recordWord(_event(i, WordRecitationStatus.current));
          break;
        }
        final heard = phonemes.substring(offset, followingOffset);
        final word = _event(
          i,
          atVerseBoundary
              ? WordRecitationStatus.unconfirmed
              : omitted
              ? WordRecitationStatus.omitted
              : WordRecitationStatus.incorrect,
          recognized: heard,
          similarity: atVerseBoundary || omitted
              ? 0
              : PhonemeUtils.similarityScore(heard, reference),
          phonemeStart: omitted ? null : offset,
          phonemeEnd: omitted ? null : followingOffset,
        );
        final recorded = _recordWord(word);
        if (recorded && stopOnConfirmedError && !atVerseBoundary) {
          final retry = _findConfirmedRetry(
            phonemes,
            i,
            followingOffset,
            followingVerse: followingVerse,
          );
          if (retry == null) {
            _blockedWord = word;
            break;
          }
          offset = retry + reference.length;
          _recordWord(
            _event(
              i,
              WordRecitationStatus.corrected,
              recognized: phonemes.substring(retry, offset),
              similarity: 1,
              phonemeStart: retry,
              phonemeEnd: offset,
            ),
          );
        } else {
          offset = followingOffset;
        }
        _activeWordIndex = i + 1;
        continue;
      }

      _recordWord(_event(i, WordRecitationStatus.current));
      break;
    }

    _consumedPhonemes = offset - startOffset;
    return wordStatuses;
  }

  int? _findConfirmedRetry(
    String phonemes,
    int index,
    int followingOffset, {
    required QuranVersePhonemes? followingVerse,
  }) {
    // Words that provided evidence for the error are before the retry. Do
    // not use them to satisfy the blocked word, even if some are identical.
    final continued = _matchRun(
      _references,
      index + 1,
      phonemes,
      followingOffset,
    );
    var boundary = continued.end;
    if (followingVerse != null &&
        continued.words == _references.length - index - 1 &&
        boundary < phonemes.length) {
      final next = followingVerse.ayaPhonemesList
          .map(PhonemeUtils.cleanPhonemes)
          .toList();
      final followingRun = _matchRun(next, 0, phonemes, boundary);
      final currentRun = _matchRun(_references, index, phonemes, boundary);
      if (followingRun.end >= currentRun.end) {
        if (followingRun.incomplete) return null;
        boundary = followingRun.end;
      }
    }
    final expected = _references[index];
    final preceding = index == 0 ? '' : _references[index - 1];
    for (
      var retry = boundary;
      retry + expected.length <= phonemes.length;
      retry++
    ) {
      if (!_matchesAt(phonemes, retry, expected)) continue;
      final retryRun = _matchRun(_references, index, phonemes, retry);
      if (retry == boundary &&
          (retryRun.incomplete ||
              retryRun.end == phonemes.length ||
              index == _references.length - 1 ||
              retryRun.words >= 2)) {
        return retry;
      }

      // Away from the known boundary, require a surrounding phrase so a
      // substring of an unrelated word cannot release the block on its own.
      final leadIn = retry - preceding.length;
      if (leadIn >= boundary &&
          preceding.length + expected.length >= 8 &&
          _matchesAt(phonemes, leadIn, preceding)) {
        return retry;
      }
      if (retryRun.words >= 2 && retryRun.end - retry >= 8) return retry;
    }
    return null;
  }

  bool _recordWord(WordMatchEvent word) {
    final index = word.wordIndex;
    final previous = _wordStatuses[index];
    if (_lastReplayWordIndex != null) {
      final matched =
          word.status == WordRecitationStatus.matched ||
          word.status == WordRecitationStatus.corrected;
      if (matched) _lastReplayWordIndex = index;
      if (previous.status == WordRecitationStatus.matched ||
          previous.status == WordRecitationStatus.corrected) {
        return false;
      }
      if (matched &&
          (previous.status == WordRecitationStatus.incorrect ||
              previous.status == WordRecitationStatus.omitted ||
              (previous.status == WordRecitationStatus.unconfirmed &&
                  previous.recognizedPhonemes.isNotEmpty))) {
        word = _event(
          index,
          WordRecitationStatus.corrected,
          recognized: word.recognizedPhonemes,
          similarity: word.similarity,
          phonemeStart: word.phonemeStart,
          phonemeEnd: word.phonemeEnd,
        );
      } else if (word.status == WordRecitationStatus.current &&
          previous.status != WordRecitationStatus.unspoken) {
        return false;
      }
    }
    _wordStatuses[index] = word;
    return true;
  }

  void _recordInterruptedWord(String phonemes, int start, int end, int index) {
    final heard = phonemes.substring(start, end);
    final similarity = PhonemeUtils.similarityScore(heard, _references[index]);
    if (similarity >= 0.7 && similarity < 1) {
      _recordWord(
        _event(
          index,
          WordRecitationStatus.unconfirmed,
          recognized: heard,
          similarity: similarity,
          phonemeStart: start,
          phonemeEnd: end,
        ),
      );
    }
  }

  ({int offset, int? wordIndex})? _findReplay(
    String phonemes,
    int offset,
    int index, {
    required QuranVersePhonemes? following,
  }) {
    // Search only the stall and its immediate tail, within this ayah.
    final retrySpan = index == _references.length
        ? 0
        : math.min(24, _references[index].length + 3);
    final followingWords = following != null && _references.length - index <= 2
        ? following.ayaPhonemesList.map(PhonemeUtils.cleanPhonemes).toList()
        : const <String>[];
    final last = math.min(offset + retrySpan, phonemes.length - 1);
    for (var start = offset; start <= last; start++) {
      int? winner;
      var bestEnd = start;
      var strong = false;
      var tied = false;
      for (var word = 0; word < index; word++) {
        final match = _matchRun(_references, word, phonemes, start);
        final hasAnchor = match.words >= 2 && match.end - start >= 8;
        if ((!hasAnchor && !match.incomplete) || match.end == start) continue;
        if (match.end > bestEnd) {
          winner = word;
          bestEnd = match.end;
          strong = hasAnchor;
          tied = false;
        } else if (match.end == bestEnd) {
          tied = true;
        }
      }
      final expected = _matchRun(_references, index, phonemes, start);
      final skippedWord = _matchRun(_references, index + 1, phonemes, start);
      final nextVerse = _matchRun(followingWords, 0, phonemes, start);
      final forwardEnd = math.max(
        expected.end,
        math.max(skippedWord.end, nextVerse.end),
      );
      // Prefer an established forward reading. Hold equal evidence so the
      // current verse is not closed before we can distinguish the two readings.
      if (forwardEnd > bestEnd && (winner != null || start == offset)) {
        return null;
      }
      if (winner != null) {
        return (
          offset: start,
          wordIndex: strong && !tied && forwardEnd < bestEnd ? winner : null,
        );
      }
    }
    return null;
  }

  static ({int words, int end, bool incomplete}) _matchRun(
    List<String> references,
    int startWord,
    String phonemes,
    int start,
  ) {
    var offset = start;
    for (var index = startWord; index < references.length; index++) {
      final word = references[index];
      final available = phonemes.length - offset;
      if (available < word.length) {
        return (
          words: index - startWord,
          end: offset,
          incomplete:
              available == 0 ||
              _matchesAt(phonemes, offset, word.substring(0, available)),
        );
      }
      if (!_matchesAt(phonemes, offset, word)) {
        return (words: index - startWord, end: offset, incomplete: false);
      }
      offset += word.length;
    }
    return (
      words: math.max(0, references.length - startWord),
      end: offset,
      incomplete: false,
    );
  }

  (int, WordRecitationStatus, WordMatchEvent?)? _recoverInVerse(
    String phonemes,
    int offset,
    int index,
  ) {
    if (index == 0 || index + 2 >= _references.length) return null;
    final expected = _references[index];
    final anchor = _references.skip(index).take(3).join();
    if (anchor.length < 12) return null;

    int? found;
    final last = math.min(
      offset + math.min(16, expected.length + 3),
      phonemes.length - anchor.length,
    );
    for (var i = offset + 3; i <= last; i++) {
      if (!_matchesAt(phonemes, i, anchor)) continue;
      if (found != null) return null;
      found = i;
    }
    if (found == null) return null;

    final heard = phonemes.substring(offset, found);
    bool same(String reference) =>
        heard.length == reference.length && _matchesAt(heard, 0, reference);

    // Re-reading a nearby word without changing it is not an addition.
    if (_references.take(index).skip(math.max(0, index - 2)).any(same)) {
      return (found, WordRecitationStatus.matched, null);
    }
    final similar = PhonemeUtils.similarityScore(heard, expected);
    if (similar >= 0.7 && similar < 1) {
      return (found, WordRecitationStatus.corrected, null);
    }
    final known = _references.indexWhere(same);
    if (known < 0 || known >= _wordsText.length || heard.length < 5) {
      return null;
    }
    return (
      found,
      WordRecitationStatus.matched,
      WordMatchEvent(
        wordIndex: index,
        wordText: _wordsText[known],
        referencePhonemes: '',
        recognizedPhonemes: heard,
        similarity: 0,
        status: WordRecitationStatus.added,
        phonemeStart: offset,
        phonemeEnd: found,
      ),
    );
  }

  int? _confirmedReplacementEnd(
    String phonemes,
    int offset,
    int wordIndex, {
    required bool allowShorterSpan,
  }) {
    if (wordIndex + 2 >= _references.length) return null;
    final next = _references[wordIndex + 1];
    final following = _references[wordIndex + 2];
    if (next.length < 3 || following.length < 3) return null;
    final expectedLength = _references[wordIndex].length;
    int? confirmedEnd;
    for (
      var end = offset + (allowShorterSpan ? 1 : expectedLength);
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
