import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/phoneme_matcher.dart';
import 'package:mathani/core/services/recitation/recitation_models.dart';
import 'package:mathani/core/services/recitation/recitation_phoneme_repository.dart';
import 'package:mathani/core/services/recitation/zipformer_alignment.dart';
import 'package:mathani/core/utils/phoneme_utils.dart';

void main() {
  group('PhonemeUtils Tests', () {
    test('Zero cost markers are correctly identified and cleaned', () {
      expect(PhonemeUtils.isZeroCostMarker(0x0686), isTrue); // ڇ
      expect(PhonemeUtils.isZeroCostMarker(0x06DC), isTrue); // ۜ
      expect(PhonemeUtils.isZeroCostMarker(0x0640), isTrue); // ـ

      const raw = 'بِـسـمِۦ';
      final cleaned = PhonemeUtils.cleanPhonemes(raw);
      expect(cleaned.contains('ـ'), isFalse);
    });

    test('Equivalent glyphs match properly', () {
      expect(PhonemeUtils.isEquivalentGlyph(0x0645, 0x06FE), isTrue); // م <-> ۾
      expect(PhonemeUtils.isEquivalentGlyph(0x0646, 0x06BA), isTrue); // ن <-> ں
    });

    test('Similarity score returns 1.0 for identical strings', () {
      const ph = 'بِسمِللَااهِ';
      expect(PhonemeUtils.similarityScore(ph, ph), equals(1.0));
    });

    test('Similarity score detects close pronunciations', () {
      const ref = 'ررَحمَاانِ';
      const asr = 'ررَحمَانِ'; // Slight madd difference
      final sim = PhonemeUtils.similarityScore(asr, ref);
      expect(sim, greaterThan(0.7));
    });
  });

  group('PhonemeWordMatcher Tests', () {
    test('Correctly matches words sequentially', () {
      const verse = QuranVersePhonemes(
        verseKey: '1:1',
        ayaText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        ayaPhoneme: 'بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم',
        ayaPhonemesList: ['بِسمِ', 'للَااهِ', 'ررَحمَاانِ', 'ررَحِۦۦۦۦم'],
        surahNameAr: 'الفاتحة',
        surahNameEn: 'Al-Fatihah',
        rules: [],
      );

      final matcher = PhonemeWordMatcher(referenceVerse: verse);
      expect(matcher.wordStatuses.length, equals(4));
      expect(
        matcher.wordStatuses[0].status,
        equals(WordRecitationStatus.current),
      );

      // Simulate partial recitation: "بسم الله"
      matcher.processLivePhonemes('بِسمِللَااهِ');
      expect(
        matcher.wordStatuses[0].status,
        equals(WordRecitationStatus.matched),
      );
      expect(
        matcher.wordStatuses[1].status,
        equals(WordRecitationStatus.matched),
      );
      expect(matcher.activeWordIndex, equals(2));
    });

    test('Detects omitted words when user skips a word', () {
      const verse = QuranVersePhonemes(
        verseKey: '1:1',
        ayaText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        ayaPhoneme: 'بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم',
        ayaPhonemesList: ['بِسمِ', 'للَااهِ', 'ررَحمَاانِ', 'ررَحِۦۦۦۦم'],
        surahNameAr: 'الفاتحة',
        surahNameEn: 'Al-Fatihah',
        rules: [],
      );

      final matcher = PhonemeWordMatcher(referenceVerse: verse);

      // Reciter said "بسم" then jumped directly to "الرحمن" (skipping "الله")
      matcher.processLivePhonemes('بِسمِ');
      expect(
        matcher.wordStatuses[0].status,
        equals(WordRecitationStatus.matched),
      );

      matcher.processLivePhonemes('بِسمِررَحمَاانِ');
      expect(
        matcher.wordStatuses[0].status,
        equals(WordRecitationStatus.matched),
      );
      expect(
        matcher.wordStatuses[1].status,
        equals(WordRecitationStatus.omitted),
      );
      expect(
        matcher.wordStatuses[2].status,
        equals(WordRecitationStatus.matched),
      );
    });

    test('Partial word input does not throw ArgumentError and waits in current status', () {
      const verse = QuranVersePhonemes(
        verseKey: '1:1',
        ayaText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        ayaPhoneme: 'بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم',
        ayaPhonemesList: ['بِسمِ', 'للَااهِ', 'ررَحمَاانِ', 'ررَحِۦۦۦۦم'],
        surahNameAr: 'الفاتحة',
        surahNameEn: 'Al-Fatihah',
        rules: [],
      );

      final matcher = PhonemeWordMatcher(referenceVerse: verse);

      // Reader said only part of "بسم" -> "بِ" (shorter than refPh.length)
      expect(() => matcher.processLivePhonemes('بِ'), returnsNormally);
      expect(
        matcher.wordStatuses[0].status,
        equals(WordRecitationStatus.current),
      );
      expect(matcher.activeWordIndex, equals(0));
      expect(matcher.consumedPhonemes, equals(0));
    });
  });

  group('Free Mode Matching & Candidate Ranking (Phase 4 Acceptance)', () {
    late RecitationPhonemeRepository repo;

    setUp(() {
      repo = RecitationPhonemeRepository();
      // إعداد بيانات اصطناعية لتمثيل يوسف وهود ويونس والرحمن
      final mockVerses = {
        '10:1': {
          'aya_text': 'الر تِلْكَ آيَاتُ الْكِتَابِ الْحَكِيمِ',
          'aya_phoneme': 'الرتِلكَءَايَـٰتُٱلكِتَـٰبِٱلحَكِيمِ',
          'aya_phonemes_list': [
            'الر',
            'تِلكَ',
            'ءَايَـٰتُ',
            'ٱلكِتَـٰبِ',
            'ٱلحَكِيمِ',
          ],
          'suraname_ar': 'يونس',
          'suraname_en': 'Yunus',
          'rules': [],
        },
        '11:1': {
          'aya_text': 'الر كِتَابٌ أُحْكِمَتْ آيَاتُهُ',
          'aya_phoneme': 'الركِتَـٰبٌأُحكِمَتءَايَـٰتُهُ',
          'aya_phonemes_list': ['الر', 'كِتَـٰبٌ', 'أُحكِمَت', 'ءَايَـٰتُهُ'],
          'suraname_ar': 'هود',
          'suraname_en': 'Hud',
          'rules': [],
        },
        '12:1': {
          'aya_text': 'الر تِلْكَ آيَاتُ الْكِتَابِ الْمُبِينِ',
          'aya_phoneme': 'الرتِلكَءَايَـٰتُٱلكِتَـٰبِٱلمُبِينِ',
          'aya_phonemes_list': [
            'الر',
            'تِلكَ',
            'ءَايَـٰتُ',
            'ٱلكِتَـٰبِ',
            'ٱلمُبِينِ',
          ],
          'suraname_ar': 'يوسف',
          'suraname_en': 'Yusuf',
          'rules': [],
        },
        '55:12': {
          'aya_text': 'وَالْحَبُّ ذُو الْعَصْفِ وَالرَّيْحَانُ',
          'aya_phoneme': 'وَٱلحَبُّذُوٱلعَصفِوَٱلرَّيحَانُ',
          'aya_phonemes_list': ['وَٱلحَبُّ', 'ذُو', 'ٱلعَصفِ', 'وَٱلرَّيحَانُ'],
          'suraname_ar': 'الرحمن',
          'suraname_en': 'Ar-Rahman',
          'rules': [],
        },
        '55:13': {
          'aya_text': 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
          'aya_phoneme': 'فَبِأَيِّءَالَاءِرَبِّكُمَاتُكَذِّبَانِ',
          'aya_phonemes_list': [
            'فَبِأَيِّ',
            'ءَالَاءِ',
            'رَبِّكُمَا',
            'تُكَذِّبَانِ',
          ],
          'suraname_ar': 'الرحمن',
          'suraname_en': 'Ar-Rahman',
          'rules': [],
        },
      };

      repo.loadForTesting(mockVerses);
    });

    test(
      'Common prefix alone (Yusuf 1 / Hud 1 / Yunus 1 "الر") remains pending',
      () {
        // فقط "الر" مدخل مشترك بدون كلمات مميزة
        final match = repo.findBestMatchingVerse('الر');
        expect(
          match,
          isNull,
          reason: 'البداية المشتركة يجب أن تظل معلقة حتى اكتمال الدليل',
        );
      },
    );

    test(
      'Full distinct evidence identifies Surah Yusuf verse 1 accurately',
      () {
        // إدخال مميز لكامل الآية: "الر تلك آيات الكتاب المبين"
        final match = repo.findBestMatchingVerse(
          'الرتِلكَءَايَـٰتُٱلكِتَـٰبِٱلمُبِينِ',
        );
        expect(match, isNotNull);
        expect(match!.verseKey, equals('12:1'));
        expect(match.surahNameAr, equals('يوسف'));
      },
    );

    test(
      'Contextual continuity correctly resolves repeated verses (Ar-Rahman 13)',
      () {
        // تلاوة "فبأي آلاء ربكما تكذبان" بعد الآية 12
        final match = repo.findBestMatchingVerse(
          'فَبِأَيِّءَالَاءِرَبِّكُمَاتُكَذِّبَانِ',
          previousSurah: 55,
          previousAyah: 12,
        );
        expect(match, isNotNull);
        expect(match!.verseKey, equals('55:13'));
        expect(match.surahNameAr, equals('الرحمن'));
      },
    );

    test(
      'Silence or short noise returns null and never defaults to Al-Fatihah',
      () {
        expect(repo.findBestMatchingVerse(''), isNull);
        expect(repo.findBestMatchingVerse('طس'), isNull);
        expect(repo.findBestMatchingVerse('ضجيج عشوائي غير قرآني'), isNull);
      },
    );
  });

  test('ranks past a long shared prefix and holds repeated phrases', () {
    final common = List.filled(42, 'a').join();
    Map<String, dynamic> verse(String phonemes) => {
      'aya_text': 'synthetic',
      'aya_phoneme': phonemes,
      'aya_phonemes_list': [phonemes],
      'suraname_ar': '',
      'suraname_en': '',
      'rules': [],
    };
    final repo = RecitationPhonemeRepository()
      ..loadForTesting({
        '10:1': verse('${common}bbbb'),
        '12:1': verse('${common}cccc'),
        '55:13': verse('repeatphrase'),
        '55:16': verse('repeatphrase'),
      });
    expect(repo.findBestMatchingVerse(common), isNull);
    expect(repo.findBestMatchingVerse('${common}cccc')?.verseKey, '12:1');
    expect(repo.findBestMatchingVerse('repeatphrase'), isNull);
  });

  group('Zipformer verse boundary', () {
    late ZipformerAlignment alignment;

    Map<String, dynamic> verse(List<String> words) => {
      'aya_text': words.join(' '),
      'aya_phoneme': words.join(),
      'aya_phonemes_list': words,
      'suraname_ar': 'الكهف',
      'suraname_en': 'Al-Kahf',
      'rules': [],
    };

    ZipformerAlignment buildAlignment([
      List<String> nextWords = const ['first', 'second', 'third'],
    ]) {
      final repository = RecitationPhonemeRepository()
        ..loadForTesting({
          '18:54': verse(['alfa', 'bravo']),
          '18:55': verse(['start', 'middle', 'last']),
          '18:56': verse(nextWords),
        });
      return ZipformerAlignment(repository);
    }

    setUp(() {
      alignment = buildAlignment();
    });

    List<ZipformerVerseAlignment> align(
      String hypothesis, {
      int startAyah = 54,
      int endAyah = 56,
      bool isFinal = false,
    }) => alignment.align(
      hypothesis,
      surah: 18,
      startAyah: startAyah,
      endAyah: endAyah,
      isFinal: isFinal,
    );

    List<String> positions(List<ZipformerVerseAlignment> verses) =>
        verses.map((verse) => verse.verse.verseKey).toList();

    const throughPenultimate = 'alfabravostartmiddle';

    for (final gap in ['', 'laslas']) {
      final ending = gap.isEmpty ? 'omission' : 'repeated partial ending';
      test('recovers from $ending after the next two words', () {
        final partial = align('$throughPenultimate${gap}first');
        expect(positions(partial), ['18:54', '18:55']);
        expect(partial.last.isComplete, isFalse);
        expect(partial.last.words.last.status, WordRecitationStatus.current);

        final resumed = align('$throughPenultimate${gap}firstsecond');
        expect(positions(resumed), ['18:54', '18:55', '18:56']);
        expect(resumed[1].isComplete, isTrue);
        expect(resumed[1].words.last.wordIndex, 2);
        expect(resumed[1].words.last.status, WordRecitationStatus.unconfirmed);
        expect(resumed[1].consumedPhonemes, 'startmiddle'.length + gap.length);
        expect(
          resumed.last.words.take(2).map((word) => word.status),
          everyElement(WordRecitationStatus.matched),
        );
      });
    }

    test('ordinary progression matches an exact ending and the next word', () {
      final result = align('${throughPenultimate}lastfirst');
      expect(positions(result), ['18:54', '18:55', '18:56']);
      expect(result[1].isComplete, isTrue);
      expect(result[1].words.last.status, WordRecitationStatus.matched);
      expect(result.last.words.first.status, WordRecitationStatus.matched);
    });

    test('retains an exact ending while waiting past two full repeats', () {
      const repeatedEnding = '${throughPenultimate}lastlastlast';
      final partial = align('${repeatedEnding}first');
      expect(partial[1].words.last.status, WordRecitationStatus.matched);
      expect(
        partial
            .skip(2)
            .expand((verse) => verse.words)
            .map((word) => word.status),
        isNot(contains(WordRecitationStatus.matched)),
      );

      final resumed = align('${repeatedEnding}firstsecondthird');
      expect(positions(resumed), ['18:54', '18:55', '18:56']);
      expect(resumed[1].isComplete, isTrue);
      expect(resumed[1].words.last.status, WordRecitationStatus.matched);
      expect(
        resumed.last.words.map((word) => word.status),
        everyElement(WordRecitationStatus.matched),
      );
    });

    test('reports an unresolved ending at stop without advancing', () {
      final result = align('${throughPenultimate}las', isFinal: true);
      expect(positions(result), ['18:54', '18:55']);
      expect(result.last.words.last.status, WordRecitationStatus.unconfirmed);
    });

    test('selected range excludes evidence from an out-of-range verse', () {
      final result = align('${throughPenultimate}firstsecond', endAyah: 55);
      expect(positions(result), ['18:54', '18:55']);
      expect(result.last.isComplete, isFalse);
      expect(result.last.words.last.status, WordRecitationStatus.current);
    });

    test('keeps position before the penultimate word has been matched', () {
      final result = align('alfabravostartfirstsecond');
      expect(positions(result), ['18:54', '18:55']);
      expect(result.last.isComplete, isFalse);
      expect(result.last.words[1].status, WordRecitationStatus.current);
    });

    test('recovers an unclear two-word ending with three anchors', () {
      final session = alignment.newSession(
        surah: 18,
        startAyah: 54,
        endAyah: 56,
      );
      final partial = session.update('alfabravostartfirstsecond');
      expect(positions(partial), ['18:54', '18:55']);
      expect(partial.last.words[1].status, WordRecitationStatus.current);

      final continued = session.update('alfabravostartfirstsecondthird');
      expect(positions(continued), ['18:54', '18:55', '18:56']);
      expect(
        continued[1].words.skip(1).map((word) => word.status),
        everyElement(WordRecitationStatus.unconfirmed),
      );
    });

    test('reports an omitted ayah once after a distinct following opening', () {
      final session = alignment.newSession(
        surah: 18,
        startAyah: 54,
        endAyah: 56,
      );
      final partial = session.update('alfabravofirstsecond');
      expect(
        partial.expand((verse) => verse.words).map((word) => word.status),
        isNot(contains(WordRecitationStatus.omittedVerse)),
      );
      final continued = session.update('alfabravofirstsecondthird');
      expect(positions(continued), ['18:54', '18:55', '18:56']);
      expect(
        continued[1].words.single.status,
        WordRecitationStatus.omittedVerse,
      );
      expect(continued[1].isComplete, isFalse);
      expect(continued[2].isComplete, isTrue);
    });

    test('keeps position on ambiguous or distant next-verse starts', () {
      final distantGap = List.filled(200, 'z').join();
      for (final continuation in [
        'firstsecondfirstsecond',
        '${distantGap}firstsecond',
      ]) {
        final result = align(throughPenultimate + continuation);
        expect(positions(result), ['18:54', '18:55']);
        expect(result.last.words.last.status, WordRecitationStatus.current);
      }
    });

    test('retains the stronger opening when its prefix recurs later', () {
      const nextWords = ['first', 'second', 'join', 'first', 'second', 'end'];
      alignment = buildAlignment(nextWords);
      const throughPartialEnding = '${throughPenultimate}las';

      final early = align('${throughPartialEnding}firstsecond');
      expect(positions(early), ['18:54', '18:55', '18:56']);

      final later = align(throughPartialEnding + nextWords.join());
      expect(positions(later), ['18:54', '18:55', '18:56']);
      expect(later[1].consumedPhonemes, early[1].consumedPhonemes);
      expect(later[1].words.last.status, WordRecitationStatus.unconfirmed);
      expect(later.last.isComplete, isTrue);
      expect(
        later.last.words.map((word) => word.status),
        everyElement(WordRecitationStatus.matched),
      );
    });

    test('an uncertain first word following a matched verse is neutral', () {
      for (final trial in [
        ('stert', WordRecitationStatus.incorrect),
        ('', WordRecitationStatus.omitted),
      ]) {
        final (opening, standaloneStatus) = trial;
        final continuation = '${opening}middlelast';
        final standalone = align(continuation, startAyah: 55);
        expect(standalone.single.words.first.status, standaloneStatus);

        final crossed = align('alfabravo$continuation');
        expect(positions(crossed), ['18:54', '18:55']);
        expect(crossed.last.isComplete, isTrue);
        expect(crossed.last.words.map((word) => word.status), [
          WordRecitationStatus.unconfirmed,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
        ]);
      }
    });

    test('a short opening waits for two words across a verse boundary', () {
      const shortOpening = 'starmiddle';
      final partial = align('alfabravo$shortOpening');
      expect(partial.last.words.first.status, WordRecitationStatus.current);

      final standalone = align('${shortOpening}last', startAyah: 55);
      expect(
        standalone.single.words.first.status,
        WordRecitationStatus.current,
      );

      final crossed = align('alfabravo${shortOpening}last');
      expect(positions(crossed), ['18:54', '18:55']);
      expect(crossed.last.isComplete, isTrue);
      expect(crossed.last.words.map((word) => word.status), [
        WordRecitationStatus.unconfirmed,
        WordRecitationStatus.matched,
        WordRecitationStatus.matched,
      ]);
    });
  });

  group('Zipformer restart within the current verse', () {
    Map<String, dynamic> verse(List<String> words) => {
      'aya_text': words.join(' '),
      'aya_phoneme': words.join(),
      'aya_phonemes_list': words,
      'suraname_ar': 'الإسراء',
      'suraname_en': 'Al-Isra',
      'rules': [],
    };

    ZipformerAlignmentSession sessionFor(
      List<String> words, {
      List<String> following = const ['bridge', 'second', 'continuation'],
      bool stopOnConfirmedError = false,
    }) {
      final repository = RecitationPhonemeRepository()
        ..loadForTesting({'17:28': verse(words), '17:29': verse(following)});
      return ZipformerAlignment(repository).newSession(
        surah: 17,
        startAyah: 28,
        endAyah: 29,
        stopOnConfirmedError: stopOnConfirmedError,
      );
    }

    test('strict practice waits for two words before blocking an omission', () {
      const words = ['alpha', 'bravo', 'charlie', 'delta', 'extra'];
      final strict = sessionFor(words, stopOnConfirmedError: true);
      final ordinary = sessionFor(words);

      final partial = strict.update('alphacharlie').single;
      expect(partial.blockedWord, isNull);
      expect(partial.words[1].status, WordRecitationStatus.current);

      const readAhead = 'alphacharliedelta';
      final waiting = strict.update(readAhead).single;
      expect(waiting.blockedWord?.wordIndex, 1);
      expect(waiting.blockedWord?.status, WordRecitationStatus.omitted);
      expect(waiting.isComplete, isFalse);
      expect(
        waiting.words.skip(2).map((word) => word.status),
        everyElement(WordRecitationStatus.unspoken),
      );
      final ordinaryResult = ordinary.update(readAhead).single;
      expect(ordinaryResult.blockedWord, isNull);
      expect(ordinaryResult.words[3].status, WordRecitationStatus.matched);

      final corrected = strict.update('${readAhead}bravo').single;
      expect(corrected.blockedWord, isNull);
      expect(corrected.words[1].status, WordRecitationStatus.corrected);
      expect(corrected.words[1].phonemeStart, readAhead.length);
      expect(corrected.words[2].status, WordRecitationStatus.current);
    });

    test('strict practice keeps confirmed errors local during live and final review', () {
      final session = sessionFor([
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'echo',
      ], stopOnConfirmedError: true);
      const incorrect = 'alphatrrixcharliedeltaechobridgesecondcontinuation';
      final live = session.update(incorrect).single;
      final finalResult = session.update(incorrect, isFinal: true).single;
      for (final blocked in [live, finalResult]) {
        expect(blocked.verse.verseKey, '17:28');
        expect(blocked.blockedWord?.wordIndex, 1);
        expect(blocked.blockedWord?.recognizedPhonemes, 'trrix');
        expect(blocked.blockedWord?.status, WordRecitationStatus.incorrect);
        expect(
          blocked.words.skip(2).map((word) => word.status),
          everyElement(WordRecitationStatus.unspoken),
        );
        expect(blocked.isComplete, isFalse);
      }
    });

    test('strict practice accepts a reread that reaches the blocked word', () {
      final session = sessionFor([
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'echo',
      ], stopOnConfirmedError: true);
      const afterMismatch = 'alphatrbovcharliedelta';
      expect(session.update(afterMismatch).single.blockedWord?.wordIndex, 1);

      // A target-like substring alone is insufficient away from a reliable
      // word boundary, and a partial replay does not reach the blocked word.
      const replay = '${afterMismatch}xbravoxalpha';
      expect(session.update(replay).single.blockedWord?.wordIndex, 1);

      final repaired = session.update(
        '${replay}bravocharliedeltaechobridgesecondcontinuation',
        isFinal: true,
      );
      expect(repaired.map((ayah) => ayah.verse.verseKey), ['17:28', '17:29']);
      expect(repaired.first.blockedWord, isNull);
      expect(repaired.first.words[1].status, WordRecitationStatus.corrected);
      expect(repaired.first.words[1].phonemeStart, replay.length);
      expect(repaired.every((ayah) => ayah.isComplete), isTrue);
    });

    test('strict practice treats a likely verse ending as uncertain', () {
      final session = sessionFor([
        'alpha',
        'bravo',
        'echo',
      ], stopOnConfirmedError: true);
      final result = session.update('alphabravoecbridgesecondcontinuation');
      expect(result.map((ayah) => ayah.verse.verseKey), ['17:28', '17:29']);
      expect(result.first.words.last.status, WordRecitationStatus.unconfirmed);
      expect(result.every((ayah) => ayah.blockedWord == null), isTrue);
    });

    for (final (location, opening, leadIn, cursor) in [
      ('the beginning', 'alphabravo', 'charliedelta', 1),
      ('the middle', 'bravocharlie', 'delta', 2),
    ]) {
      test('restarts from $location, corrects once and continues', () {
        final session = sessionFor([
          'alpha',
          'bravo',
          'charlie',
          'delta',
          'echo',
          'foxtrot',
          'golf',
        ]);
        const firstAttempt = 'alphabravocharliedeltaecxo';
        final stalled = session.update(firstAttempt).single;
        expect(stalled.words[4].status, WordRecitationStatus.current);

        final returning = '$firstAttempt$opening';
        final replaying = session.update(returning).single;
        expect(replaying.activeWordIndex, cursor);
        expect(replaying.isComplete, isFalse);

        final retry = '$returning$leadIn';
        final completed = '${retry}echofoxtrotgolfbridgesecond';
        final live = session.update(completed);
        expect(live.map((item) => item.verse.verseKey), ['17:28', '17:29']);
        expect(live.first.isComplete, isTrue);
        expect(live.last.words[1].status, WordRecitationStatus.matched);

        final finished = session.update(
          '${completed}continuation',
          isFinal: true,
        );
        final words = finished.first.words;
        expect(words.map((word) => word.wordIndex), List.generate(7, (i) => i));
        expect(words.map((word) => word.status), [
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
          WordRecitationStatus.corrected,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
        ]);
        expect(words[4].phonemeStart, retry.length);
        expect(finished.last.isComplete, isTrue);
      });
    }

    test('updates a previously marked mismatch only after hearing the fix', () {
      final session = sessionFor([
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'echo',
        'foxtrot',
        'golf',
        'hotel',
      ]);
      const firstAttempt = 'alphabravocharliedeltaecxofoxtrotgolf';
      final firstPass = session.update(firstAttempt).single;
      expect(firstPass.words[4].status, WordRecitationStatus.incorrect);

      const replay = '${firstAttempt}charliedelta';
      final pendingFix = session.update(replay).single;
      expect(pendingFix.activeWordIndex, 3);
      expect(pendingFix.words[4].status, WordRecitationStatus.incorrect);

      final fixed = session.update('${replay}echofoxtrotgolfhotel').single;
      expect(fixed.isComplete, isTrue);
      expect(fixed.words[4].status, WordRecitationStatus.corrected);
      expect(fixed.words[4].phonemeStart, replay.length);
      expect(
        fixed.words.where(
          (word) => word.status == WordRecitationStatus.corrected,
        ),
        hasLength(1),
      );
    });

    test('waits for a distinct word when two earlier phrases match', () {
      final session = sessionFor([
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'bravo',
        'charlie',
        'echo',
        'foxtrot',
      ]);
      const firstAttempt = 'alphabravocharliedeltabravocharlieecxo';
      final stalled = session.update(firstAttempt).single;
      expect(stalled.words[6].status, WordRecitationStatus.current);

      const ambiguous = '${firstAttempt}bravocharlie';
      final pending = session.update(ambiguous).single;
      expect(pending.activeWordIndex, isNull);
      expect(pending.words[6].status, WordRecitationStatus.current);

      final replaying = session.update('${ambiguous}delta').single;
      expect(replaying.activeWordIndex, 3);
      expect(replaying.isComplete, isFalse);
    });

    test(
      'keeps forward progress when an earlier phrase starts the same way',
      () {
        final session = sessionFor([
          'alpha',
          'bravo',
          'charlie',
          'alpha',
          'bravo',
          'delta',
        ]);
        const firstAttempt = 'alphabravocharliealpya';
        final stalled = session.update(firstAttempt).single;
        expect(stalled.words[3].status, WordRecitationStatus.current);

        const retry = '${firstAttempt}alphabravo';
        final pending = session.update(retry).single;
        expect(pending.activeWordIndex, isNull);

        final fixed = session.update('${retry}delta').single;
        expect(fixed.isComplete, isTrue);
        expect(fixed.words.map((word) => word.status), [
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
          WordRecitationStatus.corrected,
          WordRecitationStatus.matched,
          WordRecitationStatus.matched,
        ]);
        expect(fixed.words.first.phonemeStart, 0);
        expect(fixed.words[3].phonemeStart, firstAttempt.length);
      },
    );

    test('retains a verified ending after a partial replay', () {
      for (final advance in [false, true]) {
        final session = sessionFor([
          'alpha',
          'bravo',
          'charlie',
          'delta',
          'echo',
        ]);
        const original = 'alphabravocharliedeltaecho';
        session.update(original);

        const replay = '${original}bravocharliedelta';
        final replaying = session.update(replay).single;
        expect(replaying.activeWordIndex, 3);

        final result = session.update(
          advance ? '${replay}bridgesecondcontinuation' : replay,
          isFinal: true,
        );
        expect(result.length, advance ? 2 : 1);
        expect(result.first.words.last.status, WordRecitationStatus.matched);
        expect(
          result.first.words.last.phonemeStart,
          original.length - 'echo'.length,
        );
      }
    });

    test('distinguishes a replay from a shared next-verse opening', () {
      const firstAttempt = 'alphabravocharliedeltaecxo';
      const ambiguous = '${firstAttempt}bravocharlie';

      for (final restart in [true, false]) {
        final session = sessionFor(
          ['alpha', 'bravo', 'charlie', 'delta', 'echo'],
          following: ['bravo', 'charlie', 'hotel'],
        );
        session.update(firstAttempt);

        final pending = session.update(ambiguous);
        expect(pending.last.verse.verseKey, '17:28');
        expect(pending.last.activeWordIndex, isNull);
        expect(pending.last.isComplete, isFalse);

        if (restart) {
          final replaying = session.update('${ambiguous}delta').single;
          expect(replaying.verse.verseKey, '17:28');
          expect(replaying.activeWordIndex, 3);
        } else {
          final advanced = session.update('${ambiguous}hotel');
          expect(advanced.map((item) => item.verse.verseKey), [
            '17:28',
            '17:29',
          ]);
          expect(
            advanced.first.words.last.status,
            WordRecitationStatus.unconfirmed,
          );
          expect(advanced.last.isComplete, isTrue);
        }
      }
    });
  });

  group('Streaming opening and word evidence', () {
    const refuge = 'ءَعُۥۥذُبِللَااهِمِنَششَيطَاانِررَجِۦۦۦۦم';
    const basmala = 'بِسمِللَااهِررَحمَاانِررَحِۦۦۦۦم';

    Map<String, dynamic> verse(List<String> words) => {
      'aya_text': words.join(' '),
      'aya_phoneme': words.join(),
      'aya_phonemes_list': words,
      'suraname_ar': 'الإسراء',
      'suraname_en': 'Al-Isra',
      'rules': [],
    };

    late ZipformerAlignment alignment;
    late RecitationPhonemeRepository repository;
    setUp(() {
      repository = RecitationPhonemeRepository()
        ..loadForTesting({
          '1:1': verse(['بِسمِ', 'للَااهِ', 'ررَحمَاانِ', 'ررَحِۦۦۦۦم']),
          '1:2': verse(['another', 'unique', 'verse']),
          '9:1': verse(['direct', 'opening', 'text']),
          '17:28': verse(['alpha', 'bravo', 'last']),
          '17:29': verse(['bridge', 'second', 'continuation']),
        });
      alignment = ZipformerAlignment(repository);
    });

    test('accepts optional phrases and preserves absolute phoneme offsets', () {
      for (final opening in ['', refuge, basmala, refuge + basmala]) {
        final session = alignment.newSession(
          surah: 17,
          startAyah: 28,
          endAyah: 28,
        );
        if (opening.isNotEmpty) {
          expect(
            session
                .update(opening.substring(0, 5))
                .expand((verse) => verse.words)
                .map((word) => word.status),
            isNot(contains(WordRecitationStatus.matched)),
          );
        }
        final result = session.update('${opening}alphabravolast').single;
        expect(result.verse.verseKey, '17:28');
        expect(result.isComplete, isTrue);
        expect(result.words.first.phonemeStart, opening.length);
        expect(result.words.first.phonemeEnd, opening.length + 'alpha'.length);
        expect(result.consumedPhonemes, 'alphabravolast'.length);
      }
    });

    test('retains the free-reading position after an uncertain ending', () {
      final session = alignment.newSession();
      final leading = '$refuge${basmala}alphabravo';
      expect(session.update(leading).single.verse.verseKey, '17:28');

      final recognized = '${leading}laslasbridgesecondcontinuation';
      expect(alignment.align(recognized), isEmpty);
      final result = session.update(recognized, isFinal: true);
      expect(result.map((verse) => verse.verse.verseKey), ['17:28', '17:29']);
      expect(result.first.words.last.status, WordRecitationStatus.unconfirmed);
      expect(result.last.isComplete, isTrue);
    });

    test('preserves the first ayah of Al-Fatihah and direct At-Tawbah', () {
      final selected = alignment
          .align(refuge + basmala, surah: 1, startAyah: 1, endAyah: 1)
          .single;
      expect(selected.verse.verseKey, '1:1');
      expect(selected.isComplete, isTrue);
      expect(selected.words.first.phonemeStart, refuge.length);

      final free = alignment.align('${basmala}anotheruniqueverse');
      expect(free.map((verse) => verse.verse.verseKey), ['1:1', '1:2']);
      expect(
        alignment
            .align('directopeningtext', surah: 9, startAyah: 1, endAyah: 1)
            .single
            .isComplete,
        isTrue,
      );
    });

    test(
      'labels recognizable additions and corrections without double-counting',
      () {
        repository.loadForTesting({
          '17:28': verse([
            'alpha',
            'bravo',
            'charlie',
            'delta',
            'echo',
            'foxtrot',
          ]),
        });
        List<WordMatchEvent> read(String phrase) => alignment
            .align(
              'alpha${phrase}bravocharliedeltaechofoxtrot',
              surah: 17,
              startAyah: 28,
              endAyah: 28,
            )
            .single
            .words;

        final insertion = read('foxtrot')
            .singleWhere((word) => word.status == WordRecitationStatus.added);
        expect(insertion.wordText, 'foxtrot');
        expect(insertion.phonemeStart, 'alpha'.length);
        expect(insertion.phonemeEnd, 'alphafoxtrot'.length);
        final correction = read(
          'brevo',
        ).singleWhere((word) => word.status == WordRecitationStatus.corrected);
        expect(correction.wordText, 'bravo');
        expect(correction.phonemeStart, 'alphabrevo'.length);
        expect(
          read('alpha').map((word) => word.status),
          everyElement(WordRecitationStatus.matched),
        );
      },
    );
  });

  group('JSON Phonemes Structure Parsing', () {
    test('Parses downloaded json structure accurately', () {
      final file = File('model_zipformer/ordered_quran_phonemes.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = jsonDecode(content);
        final ruleNames = data['rule_names'] as Map<String, dynamic>;
        final verses = data['verses'] as Map<String, dynamic>;

        expect(ruleNames.isNotEmpty, isTrue);
        expect(verses.containsKey('1:1'), isTrue);

        final v1 = QuranVersePhonemes.fromJson('1:1', verses['1:1'], ruleNames);
        expect(v1.ayaText, contains('بِسْمِ'));
        expect(v1.ayaPhonemesList.length, equals(4));
        expect(v1.rules.isNotEmpty, isTrue);
      }
    });
  });

  final corpus = File('model_zipformer/ordered_quran_phonemes.json');
  group(
    'Complete local phoneme reference',
    () {
      late Map<String, dynamic> verses;
      late RecitationPhonemeRepository repository;

      setUpAll(() async {
        final data = jsonDecode(
          await File('model_zipformer/ordered_quran_phonemes.json')
              .readAsString(),
        ) as Map<String, dynamic>;
        verses = data['verses'] as Map<String, dynamic>;
        repository = RecitationPhonemeRepository()
          ..loadForTesting(
            verses,
            ruleNames: data['rule_names'] as Map<String, dynamic>,
          );
      });

      String phonemes(String key) => verses[key]['aya_phoneme'] as String;

      test('corrects a restarted phrase in Al-Isra 17:28', () {
        final words = repository.getVersePhonemes(17, 28)!.ayaPhonemesList;
        const interrupted = 7;
        const restart = 3;
        final attempt = 'ش${words[interrupted].substring(1)}';
        final stalled = '${words.take(interrupted).join()}$attempt';
        final session = ZipformerAlignment(repository)
            .newSession(surah: 17, startAyah: 28, endAyah: 29);
        expect(
          session.update(stalled).single.words[interrupted].status,
          WordRecitationStatus.current,
        );
        final replaying = session.update(
          '$stalled${words.skip(restart).take(2).join()}',
        );
        expect(replaying.single.activeWordIndex, restart + 1);

        final result = session.update(
          '$stalled${words.skip(restart).join()}${phonemes('17:29')}',
          isFinal: true,
        );
        expect(result.map((alignment) => alignment.verse.verseKey), [
          '17:28',
          '17:29',
        ]);
        expect(result.every((alignment) => alignment.isComplete), isTrue);
        expect(
          result.first.words[interrupted].status,
          WordRecitationStatus.corrected,
        );
      });

      test('accepts the Al-Isra ending in 17:29 when linked to 17:30', () {
        final words29 = repository.getVersePhonemes(17, 29)!.ayaPhonemesList;
        final words30 = repository.getVersePhonemes(17, 30)!.ayaPhonemesList;
        final ending = words29.last;
        final joined = '${ending.substring(0, ending.length - 2)}ن';
        final spoken =
            phonemes('17:28') +
            words29.take(words29.length - 1).join() +
            joined +
            words30.take(2).join();
        final result = ZipformerAlignment(repository)
            .align(spoken, surah: 17, startAyah: 28, endAyah: 30);
        expect(result.map((verse) => verse.verse.verseKey), [
          '17:28',
          '17:29',
          '17:30',
        ]);
        final confirmed = result[1].words.last;
        expect(confirmed.status, WordRecitationStatus.matched);
        expect(
          PhonemeUtils.cleanPhonemes(spoken)
              .substring(confirmed.phonemeStart!, confirmed.phonemeEnd!),
          joined,
        );
      });

      test('keeps the basmala at its actual location in 27:30', () {
        final result = ZipformerAlignment(repository)
            .align(phonemes('27:30'), surah: 27, startAyah: 30, endAyah: 30)
            .single;
        expect(result.isComplete, isTrue);
        expect(result.words.length, 8);
        expect(
          result.words.map((word) => word.status),
          everyElement(WordRecitationStatus.matched),
        );
      });

      test('resumes Al-Kahf from 18:55 into 18:56 after repeated Qubulan', () {
        final words55 = repository.getVersePhonemes(18, 55)!.ayaPhonemesList;
        final words56 = repository.getVersePhonemes(18, 56)!.ayaPhonemesList;
        final lastWord = words55.last;
        final partialWord = lastWord.substring(0, lastWord.length - 1);
        final leading =
            phonemes('18:54') +
            words55.take(words55.length - 1).join() +
            partialWord +
            partialWord;
        final alignment = ZipformerAlignment(repository);

        final weak = alignment.align(
          leading + words56.first,
          surah: 18,
          startAyah: 54,
          endAyah: 56,
        );
        expect(weak.last.verse.verseKey, '18:55');
        expect(weak.last.words.last.status, WordRecitationStatus.current);

        final resumed = alignment.align(
          leading + words56.take(2).join(),
          surah: 18,
          startAyah: 54,
          endAyah: 56,
        );
        expect(resumed.map((verse) => verse.verse.verseKey), [
          '18:54',
          '18:55',
          '18:56',
        ]);
        expect(resumed[1].words.last.status, WordRecitationStatus.unconfirmed);
        expect(resumed.last.words[1].status, WordRecitationStatus.matched);
      });

      test(
        'distinguishes Yusuf from Yunus and leaves repeated verses unresolved',
        () {
          expect(
            repository.findBestMatchingVerse(phonemes('12:1'))?.verseKey,
            '12:1',
          );
          expect(repository.findBestMatchingVerse(phonemes('55:16')), isNull);
          expect(
            repository
                .findBestMatchingVerse(
                  phonemes('55:16'),
                  previousSurah: 55,
                  previousAyah: 15,
                )
                ?.verseKey,
            '55:16',
          );
        },
      );

      test(
        'limits selected progression and measures offsets on normalized text',
        () {
          const marker = '\u06DC';
          final first = phonemes('1:1');
          final joined = marker + first + phonemes('1:2') + phonemes('1:3');
          final alignment = ZipformerAlignment(repository);
          final result = alignment.align(
            joined,
            surah: 1,
            startAyah: 1,
            endAyah: 2,
          );
          expect(result.map((v) => v.verse.verseKey), ['1:1', '1:2']);
          expect(result.every((v) => v.isComplete), isTrue);
          expect(
            result.first.consumedPhonemes,
            PhonemeUtils.cleanPhonemes(first).length,
          );
          final partial = alignment.align(
            first.substring(0, 2),
            surah: 1,
            startAyah: 1,
            endAyah: 2,
          );
          expect(
            partial.single.words.first.status,
            WordRecitationStatus.current,
          );
          expect(partial.single.consumedPhonemes, 0);
        },
      );
    },
    skip: corpus.existsSync() ? null : 'Local phoneme corpus is not installed.',
  );
}
