import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/utils/text_utils.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/services/asr_service.dart';
import 'package:mathani/data/services/text_matching_service.dart';

void main() {
  group('TextUtils Quranic Normalization Tests', () {
    test('should normalize Quranic tashkeel and stop marks properly', () {
      const quran = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝١';
      final norm = TextUtils.normalizeQuranText(quran);
      expect(norm, 'بسم الله الرحمن الرحيم');
    });

    test('should match Uthmanic spellings with standard phonetic equivalents', () {
      // الصلوة vs الصلاة
      expect(TextUtils.calculateSimilarity('الصلاة', 'ٱلصَّلَوٰةَ'), greaterThanOrEqualTo(0.95));
      // الزكاة vs الزكوة
      expect(TextUtils.calculateSimilarity('الزكاة', 'ٱلزَّكَوٰةَ'), greaterThanOrEqualTo(0.95));
      // هذا vs هاذا
      expect(TextUtils.calculateSimilarity('هاذا', 'هَٰذَا'), greaterThanOrEqualTo(0.95));
      // إبراهيم vs إبرٰهم
      expect(TextUtils.calculateSimilarity('ابراهيم', 'إِبْرَٰهِـۧمَ'), greaterThanOrEqualTo(0.95));
      // الرحمن vs الرحمٰن
      expect(TextUtils.calculateSimilarity('الرحمن', 'ٱلرَّحْمَٰنِ'), greaterThanOrEqualTo(0.95));
      // سماوات vs سمٰوٰت
      expect(TextUtils.calculateSimilarity('سماوات', 'سَمَٰوَٰتِ'), greaterThanOrEqualTo(0.95));
    });
  });

  group('TextMatchingService Alignment Tests', () {
    final service = TextMatchingService();

    final quranIkhlas = {
      112: {
        1: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        2: 'ٱللَّهُ ٱلصَّمَدُ',
        3: 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
        4: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
      }
    };

    final quranFatiha = {
      1: {
        1: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        2: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        3: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      }
    };

    test('Perfect recitation aligns 100% of words as correct', () async {
      final asrWords = [
        const AsrWord(text: 'قل', startMs: 0, endMs: 200),
        const AsrWord(text: 'هو', startMs: 200, endMs: 400),
        const AsrWord(text: 'الله', startMs: 400, endMs: 700),
        const AsrWord(text: 'احد', startMs: 700, endMs: 1000),
      ];

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: quranIkhlas,
        hintSurah: 112,
        hintStartAyah: 1,
        hintEndAyah: 1,
      );

      expect(result.matchedWords.length, 4);
      for (final word in result.matchedWords) {
        expect(word.verdict, WordVerdict.correct);
      }
      expect(result.overallConfidence, greaterThan(0.9));
    });

    test('Missing a word in the middle marks it skipped and keeps others aligned without off-by-one error', () async {
      // User says: "قل هو احد" (Missing "الله")
      final asrWords = [
        const AsrWord(text: 'قل', startMs: 0, endMs: 200),
        const AsrWord(text: 'هو', startMs: 200, endMs: 400),
        const AsrWord(text: 'احد', startMs: 400, endMs: 700),
      ];

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: quranIkhlas,
        hintSurah: 112,
        hintStartAyah: 1,
        hintEndAyah: 1,
      );

      expect(result.matchedWords.length, 4);
      expect(result.matchedWords[0].expectedWord, contains('قُلْ'));
      expect(result.matchedWords[0].verdict, WordVerdict.correct);

      expect(result.matchedWords[1].expectedWord, contains('هُوَ'));
      expect(result.matchedWords[1].verdict, WordVerdict.correct);

      // The skipped word "الله"
      expect(result.matchedWords[2].expectedWord, contains('ٱللَّهُ'));
      expect(result.matchedWords[2].verdict, WordVerdict.skipped);

      // The last word "أحد" remains correct!
      expect(result.matchedWords[3].expectedWord, contains('أَحَدٌ'));
      expect(result.matchedWords[3].verdict, WordVerdict.correct);
    });

    test('Saying a wrong word marks it incorrect without shifting subsequent words', () async {
      // User says: "قل هو كريم احد" (Replaced "الله" with "كريم")
      final asrWords = [
        const AsrWord(text: 'قل', startMs: 0, endMs: 200),
        const AsrWord(text: 'هو', startMs: 200, endMs: 400),
        const AsrWord(text: 'كريم', startMs: 400, endMs: 700),
        const AsrWord(text: 'احد', startMs: 700, endMs: 1000),
      ];

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: quranIkhlas,
        hintSurah: 112,
        hintStartAyah: 1,
        hintEndAyah: 1,
      );

      expect(result.matchedWords.length, 4);
      expect(result.matchedWords[0].verdict, WordVerdict.correct);
      expect(result.matchedWords[1].verdict, WordVerdict.correct);
      expect(result.matchedWords[2].verdict, WordVerdict.incorrect);
      expect(result.matchedWords[3].verdict, WordVerdict.correct);
    });

    test('Early stop marks remainder of ayahs as skipped', () async {
      // User recites only Ayah 1 of Surat Al-Ikhlas, while range is 1..2
      final asrWords = [
        const AsrWord(text: 'قل', startMs: 0, endMs: 200),
        const AsrWord(text: 'هو', startMs: 200, endMs: 400),
        const AsrWord(text: 'الله', startMs: 400, endMs: 700),
        const AsrWord(text: 'احد', startMs: 700, endMs: 1000),
      ];

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: quranIkhlas,
        hintSurah: 112,
        hintStartAyah: 1,
        hintEndAyah: 2,
      );

      // Ayah 1 has 4 words, Ayah 2 has 2 words (Total 6 words)
      expect(result.matchedWords.length, 6);
      expect(result.matchedWords[0].verdict, WordVerdict.correct);
      expect(result.matchedWords[1].verdict, WordVerdict.correct);
      expect(result.matchedWords[2].verdict, WordVerdict.correct);
      expect(result.matchedWords[3].verdict, WordVerdict.correct);
      expect(result.matchedWords[4].verdict, WordVerdict.skipped);
      expect(result.matchedWords[5].verdict, WordVerdict.skipped);
    });

    test('User inserting extra words does not break alignment of surrounding words', () async {
      // User says: "بسم الله يعني الرحمن الرحيم" (inserted "يعني")
      final asrWords = [
        const AsrWord(text: 'بسم', startMs: 0, endMs: 200),
        const AsrWord(text: 'الله', startMs: 200, endMs: 400),
        const AsrWord(text: 'يعني', startMs: 400, endMs: 600),
        const AsrWord(text: 'الرحمن', startMs: 600, endMs: 800),
        const AsrWord(text: 'الرحيم', startMs: 800, endMs: 1000),
      ];

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: quranFatiha,
        hintSurah: 1,
        hintStartAyah: 1,
        hintEndAyah: 1,
      );

      expect(result.matchedWords.length, 4);
      expect(result.matchedWords[0].verdict, WordVerdict.correct);
      expect(result.matchedWords[1].verdict, WordVerdict.correct);
      expect(result.matchedWords[2].verdict, WordVerdict.correct);
      expect(result.matchedWords[3].verdict, WordVerdict.correct);
    });

    test('Free mode auto detects Surah Al-Fatihah when reciter speaks without choosing surah', () async {
      final asrWords = [
        const AsrWord(text: 'الحمد', startMs: 0, endMs: 200),
        const AsrWord(text: 'لله', startMs: 200, endMs: 400),
        const AsrWord(text: 'رب', startMs: 400, endMs: 600),
        const AsrWord(text: 'العالمين', startMs: 600, endMs: 800),
      ];

      final multiSurahText = {
        1: quranFatiha[1]!,
        112: quranIkhlas[112]!,
      };

      final result = await service.matchTranscript(
        asrWords: asrWords,
        quranText: multiSurahText,
      );

      expect(result.surahNumber, 1);
      expect(result.matchedWords.any((w) => w.expectedWord.contains('ٱلْحَمْدُ') && w.verdict == WordVerdict.correct), isTrue);
    });
  });
}
