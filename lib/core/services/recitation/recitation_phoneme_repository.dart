// lib/core/services/recitation/recitation_phoneme_repository.dart
// ═══════════════════════════════════════════════════════════════════════════════
// مستودع قراءة وتحليل القاموس الفونيمي للقرآن الكريم (6236 آية)
//
// مستلهم ومطور استناداً إلى حزمة recite_quran (v1.0.5)
// المرخصة كوقف لله تعالى (No-Profit / 100% Free / لوجه الله تعالى).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../../utils/phoneme_utils.dart';
import 'recitation_model_downloader.dart';
import 'recitation_models.dart';

class RecitationPhonemeRepository {
  static final RecitationPhonemeRepository _instance =
      RecitationPhonemeRepository._internal();
  factory RecitationPhonemeRepository() => _instance;
  RecitationPhonemeRepository._internal();

  bool _isLoaded = false;
  Map<String, dynamic> _ruleNames = {};
  Map<String, dynamic> _rawVerses = {};
  Map<String, String> _normalizedReferences = {};
  final Map<String, QuranVersePhonemes> _verseCache = {};

  bool get isLoaded => _isLoaded;

  /// تحميل ملف الفونيمات من المسار المحلي المستقر.
  Future<bool> load() async {
    if (_isLoaded) return true;

    try {
      final jsonPath = await RecitationModelDownloader.getPhonemesJsonPath();
      final file = File(jsonPath);
      if (!await file.exists()) {
        return false;
      }

      final content = await file.readAsString();
      final Map<String, dynamic> data =
          json.decode(content) as Map<String, dynamic>;

      final verses = data['verses'] as Map<String, dynamic>? ?? {};
      if (verses.isEmpty) return false;
      _setData(verses, data['rule_names'] as Map<String, dynamic>? ?? {});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// تحميل بيانات مرجعية للاختبارات البرمجية المعزولة
  void loadForTesting(
    Map<String, dynamic> rawVerses, {
    Map<String, dynamic>? ruleNames,
  }) {
    _setData(rawVerses, ruleNames ?? {});
  }

  void _setData(Map<String, dynamic> verses, Map<String, dynamic> ruleNames) {
    _normalizedReferences = {
      for (final entry in verses.entries)
        entry.key: PhonemeUtils.cleanPhonemes(
          (entry.value as Map<String, dynamic>)['aya_phoneme'] as String? ?? '',
        ).trim(),
    };
    _rawVerses = verses;
    _ruleNames = ruleNames;
    _verseCache.clear();
    _isLoaded = true;
  }

  /// الحصول على بيانات الفونيمات لآية معينة بالمفتاح (مثال: "1:1" أو سورة ورقم آية).
  QuranVersePhonemes? getVersePhonemes(int surahNumber, int ayahNumber) {
    final key = '$surahNumber:$ayahNumber';
    return _rawVerses.containsKey(key) ? _getVerseByKey(key) : null;
  }

  /// Identifies the beginning of the observed transcript. Context, when given,
  /// is the last confirmed verse preceding this input.
  QuranVersePhonemes? findBestMatchingVerse(
    String phonemes, {
    int? hintSurah,
    int? previousSurah,
    int? previousAyah,
    int minEvidenceLength = 8,
  }) {
    if (!_isLoaded || _normalizedReferences.isEmpty) return null;
    final input = PhonemeUtils.cleanPhonemes(phonemes).trim();
    if (input.isEmpty) return null;

    if (previousSurah != null && previousAyah != null) {
      final nextKey = _nextVerseKey('$previousSurah:$previousAyah');
      final reference = _normalizedReferences[nextKey];
      if (reference != null && reference.isNotEmpty) {
        if (input.startsWith(reference) ||
            (input.length >= minEvidenceLength &&
                reference.startsWith(input))) {
          return _getVerseByKey(nextKey!);
        }
      }
    }
    if (input.length < minEvidenceLength) return null;

    final scope = hintSurah == null ? null : '$hintSurah:';
    final fullMatches = <String>[];
    final partialMatches = <String>[];
    var longestFullMatch = 0;
    for (final entry in _normalizedReferences.entries) {
      final reference = entry.value;
      if ((scope != null && !entry.key.startsWith(scope)) ||
          reference.length < minEvidenceLength) {
        continue;
      }
      if (input.startsWith(reference)) {
        if (reference.length > longestFullMatch) {
          fullMatches.clear();
          longestFullMatch = reference.length;
        }
        if (reference.length == longestFullMatch) fullMatches.add(entry.key);
      } else if (reference.startsWith(input)) {
        partialMatches.add(entry.key);
      }
    }
    if (partialMatches.isNotEmpty) {
      return partialMatches.length == 1 && fullMatches.isEmpty
          ? _getVerseByKey(partialMatches.single)
          : null;
    }
    if (fullMatches.length == 1) return _getVerseByKey(fullMatches.single);
    if (fullMatches.isNotEmpty) {
      // Repeated verses can be distinguished by the next words. Without that
      // evidence, the verse position is unresolved even for a perfect phrase.
      final remainder = input.substring(longestFullMatch);
      final continued = fullMatches.where((key) {
        final next = _normalizedReferences[_nextVerseKey(key)];
        return next != null &&
            (next.startsWith(remainder) || remainder.startsWith(next)) &&
            math.min(next.length, remainder.length) >= minEvidenceLength;
      }).toList();
      return continued.length == 1 ? _getVerseByKey(continued.single) : null;
    }
    return _findApproximateVerse(input, scope, minEvidenceLength);
  }

  QuranVersePhonemes? _findApproximateVerse(
    String input,
    String? scope,
    int minEvidenceLength,
  ) {
    // Limit edit-distance work. Longer exact verses were checked above.
    final window = math.min(input.length, 64);
    String? bestKey;
    var bestScore = 0.0;
    var runnerUp = 0.0;
    for (final entry in _normalizedReferences.entries) {
      if (scope != null && !entry.key.startsWith(scope)) continue;
      final reference = entry.value;
      final length = math.min(window, reference.length);
      if (length < minEvidenceLength) continue;
      final prefixLength = math.min(length, 16);
      final prefixScore = PhonemeUtils.similarityScore(
        input.substring(0, prefixLength),
        reference.substring(0, prefixLength),
      );
      if (prefixScore < .75) continue;

      final match = PhonemeUtils.similarityScore(
        input.substring(0, length),
        reference.substring(0, length),
      );
      final score = match * length / window;
      if (score > bestScore) {
        runnerUp = bestScore;
        bestScore = score;
        bestKey = entry.key;
      } else if (score > runnerUp) {
        runnerUp = score;
      }
    }
    if (bestKey == null || bestScore < .88 || bestScore - runnerUp < .07) {
      return null;
    }
    return _getVerseByKey(bestKey);
  }

  QuranVersePhonemes _getVerseByKey(String key) {
    return _verseCache.putIfAbsent(
      key,
      () => QuranVersePhonemes.fromJson(
        key,
        _rawVerses[key] as Map<String, dynamic>,
        _ruleNames,
      ),
    );
  }

  String? _nextVerseKey(String previous) {
    if (!_normalizedReferences.containsKey(previous)) return null;
    final [surah, ayah] = previous.split(':').map(int.parse).toList();
    final sameSurah = '$surah:${ayah + 1}';
    if (_normalizedReferences.containsKey(sameSurah)) return sameSurah;
    final nextSurah = '${surah + 1}:1';
    return _normalizedReferences.containsKey(nextSurah) ? nextSurah : null;
  }

  /// Re-read assets after their model package is replaced or deleted.
  void invalidate() {
    _isLoaded = false;
    _ruleNames = {};
    _rawVerses = {};
    _normalizedReferences = {};
    _verseCache.clear();
  }

  void clearCache() => _verseCache.clear();
}
