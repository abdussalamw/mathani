// lib/core/services/recitation/recitation_phoneme_repository.dart
// ═══════════════════════════════════════════════════════════════════════════════
// مستودع قراءة وتحليل القاموس الفونيمي للقرآن الكريم (6236 آية)
//
// مستلهم ومطور استناداً إلى حزمة recite_quran (v1.0.5)
// المرخصة كوقف لله تعالى (No-Profit / 100% Free / لوجه الله تعالى).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
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
      final Map<String, dynamic> data = json.decode(content) as Map<String, dynamic>;

      _ruleNames = data['rule_names'] as Map<String, dynamic>? ?? {};
      _rawVerses = data['verses'] as Map<String, dynamic>? ?? {};

      _isLoaded = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// الحصول على بيانات الفونيمات لآية معينة بالمفتاح (مثال: "1:1" أو سورة ورقم آية).
  QuranVersePhonemes? getVersePhonemes(int surahNumber, int ayahNumber) {
    final key = '$surahNumber:$ayahNumber';
    if (_verseCache.containsKey(key)) {
      return _verseCache[key];
    }

    final verseRaw = _rawVerses[key] as Map<String, dynamic>?;
    if (verseRaw == null) return null;

    final parsed = QuranVersePhonemes.fromJson(key, verseRaw, _ruleNames);
    _verseCache[key] = parsed;
    return parsed;
  }

  /// تفريغ الذاكرة عند الحاجة.
  void clearCache() {
    _verseCache.clear();
  }
}
