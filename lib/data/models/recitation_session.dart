import 'package:isar_community/isar.dart';

part 'recitation_session.g.dart';

/// جلسة تسميع محفوظة في قاعدة البيانات
@collection
class RecitationSession {
  Id id = Isar.autoIncrement;

  /// رقم السورة
  int surahNumber = 1;

  /// اسم السورة
  String surahName = '';

  /// بداية الآيات
  int startAyah = 1;

  /// نهاية الآيات
  int endAyah = 1;

  /// وضع التسميع: 'free' (حر) أو 'selected' (محدد)
  String mode = 'free';

  /// نسبة الدقة (0 - 100)
  int accuracyPercent = 0;

  /// عدد الكلمات الإجمالي
  int totalWords = 0;

  /// عدد الكلمات الصحيحة
  int correctWords = 0;

  /// مدة التلاوة بالثواني
  int durationSeconds = 0;

  /// التقييم العام (ممتاز، جيد جداً، جيد، مقبول، يحتاج تحسين)
  String overallGrade = '';

  /// النص الخام من ASR
  String rawTranscript = '';

  /// بيانات النتائج التفصيلية (JSON مشفر)
  String? resultJson;

  /// تاريخ الجلسة
  DateTime createdAt = DateTime.now();
}
