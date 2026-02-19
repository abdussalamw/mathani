import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'mushaf_downloader_service.dart'; // Import to use the robust extraction logic

/// خدمة تحميل خطوط QPC V1 (مصحف المدينة القديم)
class QPCV1FontDownloader {
  static const String _baseUrl = 
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets';
  static const String _archiveName = 'qpc_v1_by_page.tar.bz2';
  static const int _totalFonts = 604;
  
  static final Map<String, bool> _loadedFonts = {};
  static final Map<String, FontLoader> _fontLoaders = {};
  
  // Web specific: In-memory storage
  static final Map<String, Uint8List> _webParamsCache = {};

  /// التحقق مما إذا كانت جميع الخطوط موجودة
  static Future<bool> areAllFontsAvailable() async {
    if (kIsWeb) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      // Updated path to match MushafMetadataProvider's download location
      final fontsDir = Directory('${dir.path}/mushafs/madani_old_v1');
      
      if (!await fontsDir.exists()) return false;
      
      final entityCount = fontsDir.listSync().length;
      return entityCount >= _totalFonts; 
    } catch (e) {
      return false;
    }
  }
  
  /// تحميل خط صفحة محددة
  static Future<bool> loadPageFont(int pageNumber) async {
    // Format: qpc_page_001.ttf
    final fontName = 'qpc_page_${pageNumber.toString().padLeft(3, '0')}';
    final fontFamily = 'p$pageNumber-v1'; // Standardized naming to match resources
    
    // Check if already loaded in Flutter engine
    if (_loadedFonts[fontFamily] == true) return true;
    
    try {
      final fontData = await _downloadOrGetCachedFont(fontName, pageNumber);
      final fontLoader = FontLoader(fontFamily);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      _fontLoaders[fontFamily] = fontLoader;
      _loadedFonts[fontFamily] = true;
      return true;
    } catch (e) {
      debugPrint('Error loading QPC V1 font $fontName: $e');
      return false;
    }
  }

  static Future<Uint8List> _downloadOrGetCachedFont(String fontName, int pageNumber) async {
    // WEB SPECIFIC HANDLING
    if (kIsWeb) {
      final fileNameFull = '$fontName.ttf';
      if (_webParamsCache.containsKey(fileNameFull)) {
        return _webParamsCache[fileNameFull]!;
      }
      // Fallback download if needed (not implemented for individual web yet as arch is bulky)
      throw Exception('Web individual download not supported for QPC V1 yet');
    }

    // NATIVE HANDLING
    try {
        final dir = await getApplicationDocumentsDirectory();
        final List<String> searchDirs = [
          '${dir.path}/mushafs/madani_old_v1',
          '${dir.path}/madani_old_v1',
          '${dir.path}/fonts/qpc_v1',
        ];
        
        final pageNumStr = pageNumber.toString().padLeft(3, '0');
        
        final List<String> possibleNames = [
          'qpc_page_$pageNumStr.ttf',
          'qpc_page_$pageNumStr.TTF',
          'qpc_v1_page_$pageNumStr.ttf',
          'qpc_page_$pageNumber.ttf',
          '$pageNumStr.ttf',
        ];

        for (final baseDir in searchDirs) {
          for (final name in possibleNames) {
            final file = File('$baseDir/$name');
            if (await file.exists()) {
               debugPrint('SUCCESS: Found QPC V1 font at ${file.path}');
               return await file.readAsBytes();
            }
          }
        }
        
        debugPrint('ERROR: QPC V1 font not found. Checked ${searchDirs.length} dirs for page $pageNumber');

    } catch (e) {
        debugPrint('Error accessing fs: $e');
    }
    
    // If not found locally, we can't download *individual* files from tar.bz2 easily
    // unless we download the whole thing or have an API.
    // Ideally, the user should have downloaded the pack via MushafDownloaderService first.
    // But if we are here, and file is missing, we might fail.
    // For now, assume it's there or fail.
    throw Exception('Font file not found locally. Please download the Mushaf first.');
  }

  /// Helper to get the FontFamily name for a page
  static String getFontFamily(int pageNumber) {
    return 'p$pageNumber-v1';
  }
}
