import 'package:isar/isar.dart';
import 'package:mathani/core/utils/text_utils.dart';

part 'ayah.g.dart';

@collection
class Ayah {
  Id id = Isar.autoIncrement;
  
  @Index(composite: [CompositeIndex('ayahNumber')])
  int surahNumber = 1;
  
  int ayahNumber = 1;
  
  @Index() // Allow searching
  String textClean = '';      // النص بدون تشكيل للبحث

  // النص القرآني
  String text = '';           // النص البسيط
  String? textUthmani;        // الرسم العثماني (إن وُجد)
  
  // للتنقل
  int juz = 1;
  int page = 1;
  int? hizbQuarter;
  int? manzil;
  
  // للمستخدم
  bool isBookmarked = false;
  bool isFavorite = false;
  String? notes;
  
  // Constructor
  Ayah();
  
  // From JSON
  factory Ayah.fromJson(Map<String, dynamic> json, int surahNum) {
    final rawText = json['text']?.toString() ?? '';
    return Ayah()
      ..surahNumber = surahNum
      ..ayahNumber = int.tryParse(json['numberInSurah']?.toString() ?? json['verseNumber']?.toString() ?? '1') ?? 1
      ..text = rawText
      ..textClean = TextUtils.normalizeQuranText(rawText)
      ..juz = int.tryParse(json['juz']?.toString() ?? '1') ?? 1
      ..page = int.tryParse(json['page']?.toString() ?? '1') ?? 1
      ..hizbQuarter = int.tryParse(json['hizbQuarter']?.toString() ?? '0')
      ..manzil = int.tryParse(json['manzil']?.toString() ?? '0');
  }
  
  // الرقم الإجمالي في المصحف
  int get globalNumber => ayahNumber; // سيتم حسابه لاحقاً
}