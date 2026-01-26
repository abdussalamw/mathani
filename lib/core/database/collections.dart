
import 'package:isar/isar.dart';

part 'collections.g.dart';

@collection
class Surah {
  Id id = Isar.autoIncrement;

  @Index()
  late int number;

  late String nameArabic;
  late String nameEnglish;
  
  @Enumerated(EnumType.ordinal)
  late RevelationType revelation;
  
  late int numberOfAyahs;
  late int juzNumber; // Start juz
  late int page; // Start page

  bool isFavorite = false;
  int? lastReadAyah;
  DateTime? lastReadTime;
}

enum RevelationType {
  meccan,
  medinan,
}

@collection
class Ayah {
  Id id = Isar.autoIncrement;

  @Index()
  late int surahNumber;
  
  @Index()
  late int ayahNumber;

  late String textUthmani; // Drawing
  late String textSimple; // Searchable

  late int page;
  late int juz;
  late int hizbQuarter;

  bool isBookmarked = false;
  bool isFavorite = false;
  int repeatCount = 0;
  String? notes;
}

@collection
class Tafsir {
  Id id = Isar.autoIncrement;

  @Index()
  late int surahNumber;
  
  @Index()
  late int ayahNumber;

  late String tafsirName; // e.g., 'muyassar', 'saadi'
  late String text;
}

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
  
  String selectedMushafId = 'madani_font_v1'; // Default to font based
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
  late String identifier; // e.g., 'madani_v1', 'madani_v2', 'tajweed'

  late String nameArabic;
  late String nameEnglish;
  
  late String type; // 'font', 'image', 'svg'
  late String? baseUrl; // Url to download assets from
  
  bool isDownloaded = false; // Is the asset pack available locally?
  String? localPath; // Functionally used if we download images/svgs
  
  int totalPages = 604;
}

// Helper enum for Mushaf Types logic (not stored directly)
enum MushafTypeEnum {
  font,
  image,
  svg
}
