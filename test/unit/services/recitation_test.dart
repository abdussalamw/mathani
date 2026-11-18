import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/phoneme_matcher.dart';
import 'package:mathani/core/services/recitation/recitation_models.dart';
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
      expect(matcher.wordStatuses[0].status, equals(WordRecitationStatus.current));

      // Simulate partial recitation: "بسم الله"
      matcher.processLivePhonemes('بِسمِللَااهِ');
      expect(matcher.wordStatuses[0].status, equals(WordRecitationStatus.matched));
      expect(matcher.wordStatuses[1].status, equals(WordRecitationStatus.matched));
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
      expect(matcher.wordStatuses[0].status, equals(WordRecitationStatus.matched));

      matcher.processLivePhonemes('بِسمِررَحمَاانِ');
      expect(matcher.wordStatuses[0].status, equals(WordRecitationStatus.matched));
      expect(matcher.wordStatuses[1].status, equals(WordRecitationStatus.omitted));
      expect(matcher.wordStatuses[2].status, equals(WordRecitationStatus.matched));
    });
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
}
