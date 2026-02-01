import 'package:isar/isar.dart';

part 'surah.g.dart';

@collection
class Surah {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  int number = 1;
  
  String nameArabic = '';
  String nameEnglish = '';
  String nameEnglishTranslation = '';
  String revelationType = 'Meccan'; // Meccan or Medinan
  
  int numberOfAyahs = 0;
  
  // للتنقل
  int? juzStart;
  int? juzEnd;
  int? page;
  
  // للمستخدم
  bool isFavorite = false;
  int lastReadAyah = 0;
  DateTime? lastReadTime;
  
  // Constructor
  Surah();
  
  // From JSON (من API)
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah()
      ..id = int.tryParse(json['number']?.toString() ?? '1') ?? 1
      ..number = int.tryParse(json['number']?.toString() ?? '1') ?? 1
      ..nameArabic = json['name']?.toString() ?? ''
      ..nameEnglish = json['englishName']?.toString() ?? ''
      ..nameEnglishTranslation = json['englishNameTranslation']?.toString() ?? ''
      ..revelationType = json['revelationType']?.toString() ?? 'Meccan'
      ..numberOfAyahs = int.tryParse(json['numberOfAyahs']?.toString() ?? '0') ?? 0;
  }
  
  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': nameArabic,
      'englishName': nameEnglish,
      'englishNameTranslation': nameEnglishTranslation,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
    };
  }
  // Helpers for UI compatibility
  @ignore
  int get juzNumber => juzStart ?? 1;
  
  @ignore
  RevelationType get revelation => revelationType == 'Meccan' 
      ? RevelationType.meccan 
      : RevelationType.medinan;
}

enum RevelationType { meccan, medinan }