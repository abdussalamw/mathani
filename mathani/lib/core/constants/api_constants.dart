class ApiConstants {
  // Base URLs
  static const String alQuranCloudBase = 'https://api.alquran.cloud/v1';
  static const String everyAyahBase = 'https://everyayah.com/data';
  
  // Endpoints
  static const String surahs = '/surah';
  static const String surahById = '/surah/'; // + {number}
  static const String juzList = '/juz';
  
  // Reciters
  static const String minshawi = 'Minshawi_Murattal_128kbps';
  
  // Formats
  static String getAudioUrl(int surah, int ayah, String reciter) {
    String surahStr = surah.toString().padLeft(3, '0');
    String ayahStr = ayah.toString().padLeft(3, '0');
    return '$everyAyahBase/$reciter/$surahStr$ayahStr.mp3';
  }
}