// lib/core/utils/phoneme_utils.dart
// ═══════════════════════════════════════════════════════════════════════════════
// أدوات معالجة ومطابقة الرموز الصوتية القرآنية (Phoneme Utilities)
//
// مقتبس ومطور استناداً إلى خوارزميات حزمة recite_quran (v1.0.5)
// المرخصة كوقف لله تعالى (No-Profit / 100% Free / لوجه الله تعالى).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

/// أدوات مساعدة للتعامل مع الرموز الصوتية لنماذج الذكاء الاصطناعي القرآنية (Zipformer CTC).
class PhonemeUtils {
  PhonemeUtils._();

  /// الرموز التجويدية والعلامات المساعدة ذات التكلفة الصفرية في المقارنة الصوتية.
  static bool isZeroCostMarker(int codeUnit) {
    return codeUnit == 0x0686 || // 'ڇ' - قلقلة
        codeUnit == 0x06DC || // 'ۜ' - سكتة لطيفة
        codeUnit == 0x0619 || // 'ؙ' - إشمام
        codeUnit == 0x06EA || // '۪' - إمالة
        codeUnit == 0x0640; // 'ـ' - تطويل
  }

  /// التحقق من التكافؤ الصوتي بين حرفين قرآنيين (مثل الميم المقلوبة، النون المخفاة، إلخ).
  static bool isEquivalentGlyph(int asrCode, int refCode) {
    if (asrCode == refCode) return true;

    // توحيد الترتيب للمقارنة
    var code1 = asrCode;
    var code2 = refCode;
    if (code1 > code2) {
      final temp = code1;
      code1 = code2;
      code2 = temp;
    }

    // م <-> ۾ (إقلاب)
    if (code1 == 0x0645 && code2 == 0x06FE) return true;
    // ن <-> ں (إخفاء / إدغام بغير غنة)
    if (code1 == 0x0646 && code2 == 0x06BA) return true;
    // ي <-> ۦ (مد الياء)
    if (code1 == 0x064A && code2 == 0x06E6) return true;
    // و <-> ۥ (مد الواو)
    if (code1 == 0x0648 && code2 == 0x06E5) return true;
    // ا <-> ى (ألف مقصورة / قائمة)
    if (code1 == 0x0627 && code2 == 0x0649) return true;

    return false;
  }

  /// إزالة الرموز الصفرية والتطويل من النص الفونيمي.
  static String cleanPhonemes(String raw) {
    if (raw.isEmpty) return raw;
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      if (!isZeroCostMarker(code)) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// حساب تكلفة الاستبدال الصوتي بين رمز النموذج ورمز المرجع.
  static double substitutionCost(int asrCode, int refCode) {
    if (asrCode == refCode) return 0.0;
    if (isEquivalentGlyph(asrCode, refCode)) return 0.0;
    if (isZeroCostMarker(asrCode) || isZeroCostMarker(refCode)) return 0.1;
    return 1.0;
  }

  /// حساب مسافة التعديل الصوتي (Phonetic Edit Distance) الموجهة للأصوات القرآنية.
  static double phonemeEditDistance(String s1, String s2) {
    final clean1 = cleanPhonemes(s1);
    final clean2 = cleanPhonemes(s2);

    final m = clean1.length;
    final n = clean2.length;
    if (m == 0) return n.toDouble();
    if (n == 0) return m.toDouble();

    var prev = List<double>.generate(n + 1, (i) => i.toDouble());
    var curr = List<double>.filled(n + 1, 0.0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i.toDouble();
      final code1 = clean1.codeUnitAt(i - 1);

      for (int j = 1; j <= n; j++) {
        final code2 = clean2.codeUnitAt(j - 1);
        final cost = substitutionCost(code1, code2);

        final insertion = curr[j - 1] + 1.0;
        final deletion = prev[j] + 1.0;
        final substitution = prev[j - 1] + cost;

        curr[j] = math.min(insertion, math.min(deletion, substitution));
      }

      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[n];
  }

  /// حساب نسبة التطابق الصوتي بين سلسلتين فونيميتين (0.0 إلى 1.0).
  static double similarityScore(String recognized, String reference) {
    final cleanRef = cleanPhonemes(reference);
    if (cleanRef.isEmpty) return recognized.isEmpty ? 1.0 : 0.0;

    final distance = phonemeEditDistance(recognized, reference);
    final maxLen = math.max(cleanPhonemes(recognized).length, cleanRef.length);
    if (maxLen == 0) return 1.0;

    final score = 1.0 - (distance / maxLen);
    return score.clamp(0.0, 1.0);
  }
}
