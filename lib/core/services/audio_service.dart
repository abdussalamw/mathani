import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final Dio _dio = Dio();
  String? _appDocPath;

  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  /// Initialize the service by getting the document directory
  Future<void> init() async {
    if (_appDocPath != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _appDocPath = dir.path;
  }

  /// Get the local file path for a specific Ayah
  Future<String> getAyahPath(String reciterId, int surah, int ayah) async {
    await init();
    final s = surah.toString();
    // Path structure: .../audio/{reciterId}/{surah}/{ayah}.mp3
    return '$_appDocPath/audio/$reciterId/$s/$ayah.mp3';
  }

  /// Check if an Ayah file exists locally and is valid (size > 0)
  Future<bool> isAyahDownloaded(String reciterId, int surah, int ayah) async {
    final path = await getAyahPath(reciterId, surah, ayah);
    final file = File(path);
    if (!await file.exists()) return false;
    
    // Integrity check: corrupt or empty file
    if (await file.length() < 1000) { // Less than 1KB is definitely suspicious for audio
       try {
         await file.delete();
         debugPrint('Deleted corrupt/empty audio file: $path');
       } catch (e) {
         debugPrint('Failed to delete corrupt file: $e');
       }
       return false;
    }
    
    return true;
  }

  /// Generate the remote URL for an Ayah
  String getRemoteUrl(String reciterId, int surah, int ayah) {
     // Pad with leading zeros for the filename (001001.mp3)
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterId/$s$a.mp3';
  }

  /// Download a single Ayah
  Future<String?> downloadAyah(String reciterId, int surah, int ayah) async {
    try {
      final localPath = await getAyahPath(reciterId, surah, ayah);
      final file = File(localPath);

      if (await file.exists()) {
        return localPath;
      }

      // Ensure directory exists
      await file.parent.create(recursive: true);

      final url = getRemoteUrl(reciterId, surah, ayah);
      
      await _dio.download(url, localPath);
      return localPath;
    } catch (e) {
      debugPrint('Error downloading ayah $surah:$ayah - $e');
      return null;
    }
  }

  /// Get statistics for a reciter (number of downloaded Surahs and Ayahs)
  Future<Map<String, int>> getReciterStats(String reciterId) async {
    await init();
    int downloadedAyahs = 0;
    int downloadedSurahs = 0;
    
    final reciterDir = Directory('$_appDocPath/audio/$reciterId');
    if (!await reciterDir.exists()) {
      return {'ayahs': 0, 'surahs': 0};
    }

    try {
      final surahDirs = reciterDir.listSync().whereType<Directory>();
      for (var dir in surahDirs) {
        final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp3'));
        if (files.isNotEmpty) {
          downloadedSurahs++;
          downloadedAyahs += files.length;
        }
      }
    } catch (e) {
      debugPrint('Error getting stats: $e');
    }

    return {'ayahs': downloadedAyahs, 'surahs': downloadedSurahs};
  }

  /// Calculate total size of downloaded files for a reciter in MB
  Future<double> getReciterStorageUsage(String reciterId) async {
    await init();
    double totalBytes = 0;
    
    final reciterDir = Directory('$_appDocPath/audio/$reciterId');
    if (!await reciterDir.exists()) {
      return 0.0;
    }

    try {
      // Recursive listing
       await for (var entity in reciterDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating size: $e');
    }

    return totalBytes / (1024 * 1024); // Convert to MB
  }

  /// Delete all downloads for a reciter
  Future<void> deleteReciterData(String reciterId) async {
    await init();
    final reciterDir = Directory('$_appDocPath/audio/$reciterId');
    if (await reciterDir.exists()) {
      await reciterDir.delete(recursive: true);
    }
  }
}
