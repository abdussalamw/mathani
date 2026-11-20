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
