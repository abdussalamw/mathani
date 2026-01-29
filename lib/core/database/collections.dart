import 'package:isar/isar.dart';

// Export separate models
export '../../data/models/surah.dart';
export '../../data/models/ayah.dart';
export '../../data/models/tafsir.dart';
export '../../data/models/juz.dart';

part 'collections.g.dart';

@collection
class AudioCache {
  Id id = Isar.autoIncrement;

  @Index()
  late int surahNumber;
  
  @Index()
  late int ayahNumber;

  late String reciter;
  late String localPath;
  late int fileSize;
  late DateTime downloadedAt;
}

@collection
class UserSettings {
  Id id = Isar.autoIncrement;

  double fontSize = 28.0;
  String fontFamily = 'Amiri';
  
  bool isDarkMode = false;
  bool autoScroll = false;
  
  String defaultTafsir = 'muyassar';
  String defaultReciter = 'minshawi_murattal';
  
  String selectedMushafId = 'madani_font_v1'; 
}

@collection
class ReadingProgress {
  Id id = Isar.autoIncrement;

  late DateTime date;
  
  int pagesRead = 0;
  int ayahsRead = 0;
  
  int timeSpent = 0; // in seconds
  double completionPercentage = 0.0;
}

@collection
class MushafMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? identifier; 

  String? nameArabic;
  String? nameEnglish;
  String? type; 
  String? baseUrl; 
  
  bool isDownloaded = false; 
  String? localPath; 
  
  int totalPages = 604;
}

// Helper enum for Mushaf Types logic (not stored directly)
enum MushafTypeEnum {
  font,
  image,
  svg
}

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
