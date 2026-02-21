import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';

class LocalTafsirService {
  static final LocalTafsirService _instance = LocalTafsirService._internal();
  static LocalTafsirService get instance => _instance;
  LocalTafsirService._internal();

  bool _isLoaded = false;
  Map<String, String> _tafsirMap = {}; // "sura_ayah" -> tafseer
  
  static const String tafsirUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/hafs_tafseerMouaser_v3.zip';
  static const String csvFileName = 'hafs_tafseerMouaser_v3_data/tafsirMouaser_v03.csv'; // Adjusted internally if needed

  Future<bool> isTafsirDownloaded() async {
    if (kIsWeb) return false;
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/tafsir/tafsirMouaser_v03.csv');
    return await file.exists();
  }

  Future<void> downloadAndExtractTafsir({required Function(double) onProgress}) async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/tafsir');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final response = await http.Client().send(http.Request('GET', Uri.parse(tafsirUrl)));
      if (response.statusCode != 200) {
        throw Exception('Failed to download tafsir');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress((receivedBytes / totalBytes) * 0.8); // 80% for download
        }
      }

      onProgress(0.9); // extracting
      
      // Extract in compute to avoid blocking
      await compute(_extractZip, {
         'bytes': bytes,
         'path': targetDir.path
      });
      
      onProgress(1.0);
      await loadTafsirData(); // Load into memory after download
      
    } catch (e) {
      debugPrint('Error downloading tafsir: $e');
      throw e;
    }
  }

  static void _extractZip(Map<String, dynamic> args) {
    final bytes = args['bytes'] as List<int>;
    final targetPath = args['path'] as String;
    
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.csv')) {
        final outFile = File('$targetPath/tafsirMouaser_v03.csv');
        outFile.parent.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
        break; // We only need the CSV
      }
    }
  }

  Future<void> loadTafsirData() async {
    if (_isLoaded || kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/tafsir/tafsirMouaser_v03.csv');
      
      if (!await file.exists()) {
         return; // Not downloaded yet
      }
      
      final fileContentString = await file.readAsString();
      final fields = const CsvToListConverter().convert(fileContentString);
          
      // Parse CSV (skip header)
      // id,sura,aya,jozz,sura_name_en,sura_name_ar,page,line_start,line_end,aya_text,aya_text_emlaey,tafseer_narration
      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length >= 12) {
          final sura = int.tryParse(row[1].toString()) ?? 0;
          final aya = int.tryParse(row[2].toString()) ?? 0;
          final tafsir = row[11].toString();
          
          if (sura > 0 && aya > 0) {
            _tafsirMap['${sura}_$aya'] = tafsir;
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading tafsir data: $e');
    }
  }

  Future<String?> getTafsir(int sura, int aya) async {
    if (!_isLoaded) {
      await loadTafsirData();
    }
    return _tafsirMap['${sura}_$aya'];
  }
}
