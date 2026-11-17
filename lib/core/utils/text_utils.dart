import 'dart:math';

/// أدوات معالجة وتطبيع النصوص القرآنية والصوتية
class TextUtils {
  /// تطبيع عام للنص القرآني: إزالة التشكيل والعلامات وتوحيد الحروف
  static String normalizeQuranText(String text) {
    if (text.isEmpty) return '';

    String normalized = text;

    // 1. إزالة التشكيل وعلامات الضبط المصحفي والرموز الخاصة
    normalized = normalized.replaceAll(
      RegExp(
        r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08E1\u08E3-\u08FF\uFD3E\uFD3F]',
      ),
      '',
    );

    // 2. إزالة الأرقام وأقواس الآيات وعلامات الترقيم
    normalized = normalized.replaceAll(
      RegExp(r'[0-9٠-٩()\[\]{}<>«»".,؛:!?؟ـ\-_/\\|]'),
      '',
    );

    // 3. توحيد الألف بكافة أشكالها (وصل، قطع، مد)
    normalized = normalized.replaceAll(RegExp(r'[أإآٱٲٳء]'), 'ا');

    // 4. توحيد الياء والألف المقصورة
    normalized = normalized.replaceAll('ى', 'ي');

    // 5. توحيد التاء المربوطة والهاء في أواخر الكلمات
    normalized = normalized.replaceAll('ة', 'ه');

    // 6. توحيد الواو المهموزة والياء المهموزة
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ي');

    // 7. إزالة المسافات المتكررة والفراغات في الأطراف
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// تطبيع صوتي متقدم (Phonetic Normalization) لمطابقة المخرجات الصوتية من ASR مع الرسم العثماني
  /// يعالج حالات الرسم العثماني مثل (الصلوة -> الصلاة، سموت -> سماوات، ذالك -> ذلك)
  static String normalizePhonetic(String word) {
    if (word.isEmpty) return '';

    String normalized = normalizeQuranText(word);

    // 1. معالجة كلمات الرسم العثماني الشهيرة بالواو (الصلوة -> الصلاه، الزكوة -> الزكاه، الحيوة -> الحياه)
    normalized = normalized.replaceAll(RegExp(r'لوه$'), 'لاه');
    normalized = normalized.replaceAll(RegExp(r'كوه$'), 'كاه');
    normalized = normalized.replaceAll(RegExp(r'يوه$'), 'ياه');
    normalized = normalized.replaceAll(RegExp(r'نجوه$'), 'نجاه');
    normalized = normalized.replaceAll(RegExp(r'مشكوه$'), 'مشكاه');
    normalized = normalized.replaceAll(RegExp(r'غدوه$'), 'غداه');
    normalized = normalized.replaceAll(RegExp(r'منوه$'), 'مناة');

    // 2. معالجة الألف المحذوفة رسماً والمثبتة نطقاً (هاذا -> هذا، ذالك -> ذلك، لاكن -> لكن، الرحمان -> الرحمن، اسمعيل -> اسماعيل)
    normalized = normalized.replaceAll('هاذا', 'هذا');
    normalized = normalized.replaceAll('هاذه', 'هذه');
    normalized = normalized.replaceAll('هاؤلاء', 'هؤلاء');
    normalized = normalized.replaceAll('هاولاء', 'هؤلاء');
    normalized = normalized.replaceAll('ذالك', 'ذلك');
    normalized = normalized.replaceAll('لاكن', 'لكن');
    normalized = normalized.replaceAll('الرحمان', 'الرحمن');
    normalized = normalized.replaceAll('اسمعيل', 'اسماعيل');
    normalized = normalized.replaceAll('اسمعل', 'اسماعيل');
    normalized = normalized.replaceAll('ابرهم', 'ابراهيم');
    normalized = normalized.replaceAll('ابراهم', 'ابراهيم');
    normalized = normalized.replaceAll('ابرهيم', 'ابراهيم');
    normalized = normalized.replaceAll('اسحق', 'اسحاق');
    normalized = normalized.replaceAll('هرون', 'هارون');
    normalized = normalized.replaceAll('سلمن', 'سليمان');
    normalized = normalized.replaceAll('سموات', 'سماوات');
    normalized = normalized.replaceAll('سموت', 'سماوات');

    return normalized;
  }

  /// حساب نسبة التشابه بين كلمتين (0.0 إلى 1.0) بالجمع بين التطابق المباشر والصوتي ومسافة Levenshtein
  static double calculateSimilarity(String spoken, String expected) {
    if (spoken.isEmpty && expected.isEmpty) return 1.0;
    if (spoken.isEmpty || expected.isEmpty) return 0.0;

    // 1. فحص التطابق المباشر بعد التطبيع القياسي
    final normSpoken = normalizeQuranText(spoken);
    final normExpected = normalizeQuranText(expected);

    if (normSpoken == normExpected) return 1.0;

    // 2. فحص التطابق الصوتي المتقدم
    final phoneSpoken = normalizePhonetic(spoken);
    final phoneExpected = normalizePhonetic(expected);

    if (phoneSpoken == phoneExpected) return 0.98;

    // 3. حساب Levenshtein Distance على النص المطبع صوتياً
    final distance = levenshteinDistance(phoneSpoken, phoneExpected);
    final maxLen = max(phoneSpoken.length, phoneExpected.length);

    if (maxLen == 0) return 1.0;

    double sim = 1.0 - (distance / maxLen);

    // تسامح إضافي للكلمات الطويلة إذا كان الفرق حرفاً واحداً فقط
    if (maxLen >= 5 && distance == 1) {
      sim = max(sim, 0.85);
    } else if (maxLen >= 7 && distance == 2) {
      sim = max(sim, 0.75);
    }

    return sim.clamp(0.0, 1.0);
  }

  /// خوارزمية حساب مسافة التعديل (Levenshtein Distance)
  static int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
