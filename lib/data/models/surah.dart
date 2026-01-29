import 'package:isar/isar.dart';

part 'surah.g.dart';

@collection
class Surah {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late int number;
  
  late String nameArabic;
  late String nameEnglish;
  late String nameEnglishTranslation;
  late String revelationType; // Meccan or Medinan
  
  late int numberOfAyahs;
  
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
      ..id = json['number'] // Set ID explicitly to ensure upsert
      ..number = json['number']
      ..nameArabic = json['name']
      ..nameEnglish = json['englishName']
      ..nameEnglishTranslation = json['englishNameTranslation'] ?? ''
      ..revelationType = json['revelationType']
      ..numberOfAyahs = json['numberOfAyahs'];
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