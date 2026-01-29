import 'package:isar/isar.dart';

part 'ayah.g.dart';

@collection
class Ayah {
  Id id = Isar.autoIncrement;
  
  @Index(composite: [CompositeIndex('ayahNumber')])
  late int surahNumber;
  
  late int ayahNumber;
  
  // النص القرآني
  late String text;           // النص البسيط
  String? textUthmani;        // الرسم العثماني (إن وُجد)
  
  // للتنقل
  late int juz;
  late int page;
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
    return Ayah()
      ..surahNumber = surahNum
      ..ayahNumber = json['numberInSurah']
      ..text = json['text']
      ..juz = json['juz']
      ..page = json['page']
      ..hizbQuarter = json['hizbQuarter']
      ..manzil = json['manzil'];
  }
  
  // الرقم الإجمالي في المصحف
  int get globalNumber => ayahNumber; // سيتم حسابه لاحقاً
}