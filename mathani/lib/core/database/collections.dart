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
  int surahNumber = 1;
  
  @Index()
  int ayahNumber = 1;

  String reciter = '';
  String localPath = '';
  int fileSize = 0;
  DateTime downloadedAt = DateTime.now();
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

  DateTime date = DateTime.now();
  
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
  String? imageExtension;
  int pageCount = 604;
  
  bool isDownloaded = false; 
  String? localPath; 
  
  int totalPages = 604;
}

@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  @Index()
  int surahNumber = 1;
  
  @Index()
  int ayahNumber = 1;

  DateTime createdAt = DateTime.now();
  String? note;
}

// Helper enum for Mushaf Types logic (not stored directly)
enum MushafTypeEnum {
  font,
  image,
  svg
}

/// FNV-1a 32-bit hash algorithm compatible with Web (JavaScript)
int fastHash(String string) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < string.length; i++) {
    hash ^= string.codeUnitAt(i);
    hash *= 0x01000193;
    hash &= 0xFFFFFFFF;
  }
  return hash;
}
