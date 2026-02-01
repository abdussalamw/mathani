import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

/// خدمة تحميل خطوط QCF4 من GitHub
/// تدعم التحميل الفردي (Legacy) والتحميل الجماعي (Bulk)
class QCF4FontDownloader {
  static const String _baseUrl = 
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets';
  static const String _zipFileName = 'quran_fonts_qfc4.zip';
  static const int _totalFonts = 604;
  
  static final Map<String, bool> _loadedFonts = {};
  static final Map<String, FontLoader> _fontLoaders = {};
  
  // Web specific: In-memory storage since we can't write to typical FS
  static final Map<String, Uint8List> _webParamsCache = {};

  /// التحقق مما إذا كانت جميع الخطوط موجودة
  static Future<bool> areAllFontsAvailable() async {
    // On Web, always return true to skip the Bulk Download screen
    // We will rely on lazy loading with CORS proxy instead.
    if (kIsWeb) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/fonts/qcf4');
      
      if (!await fontsDir.exists()) return false;
      
      final entityCount = fontsDir.listSync().length;
      return entityCount >= _totalFonts; 
    } catch (e) {
      return false;
    }
  }

  /// تحميل وفك ضغط ملف الخطوط الكامل
  static Future<void> downloadAllFonts({
    required Function(double progress) onProgress,
    required Function(String status) onStatusChanged,
  }) async {
    // Determine target file for native, or use memory for web
    File? zipFile;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      zipFile = File('${dir.path}/$_zipFileName');
      await clearCache();
    } else {
      _webParamsCache.clear();
    }

    try {
      // 1. Download Zip
      onStatusChanged('جاري تحميل ملف الخطوط...');
      
      // We need the bytes whether it's web (memory) or native (file)
      final httpClient = http.Client();
      final request = http.Request('GET', Uri.parse('$_baseUrl/$_zipFileName'));
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
         throw Exception('Failed to download zip: ${response.statusCode}');
      }
      
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> allBytes = [];
      
      // Stream download
      await for (final chunk in response.stream) {
        allBytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes * 0.5); // 50% for download
        }
      }
      httpClient.close();
      
      final zipBytes = Uint8List.fromList(allBytes);

      if (!kIsWeb && zipFile != null) {
         await zipFile.writeAsBytes(zipBytes);
      }
      
      // 2. Extract Zip
      onStatusChanged('جاري فك ضغط الخطوط...');
      
      // Extract logic
      await _extractZipBytes(zipBytes, !kIsWeb ? (await getApplicationDocumentsDirectory()).path + '/fonts/qcf4' : null);
      
      // 3. Cleanup
      onStatusChanged('تمت العملية بنجاح');
      if (!kIsWeb && zipFile != null && await zipFile.exists()) {
        await zipFile.delete();
      }
      onProgress(1.0);
      
    } catch (e) {
      debugPrint('Error downloading all fonts: $e');
      throw e;
    }
  }

  static Future<void> _extractZipBytes(Uint8List zipBytes, String? targetPath) async {
    // For Web, we extract to _webParamsCache
    // For Native, we extract to targetPath
    
    if (kIsWeb) {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive) {
        if (file.isFile) {
           final filename = file.name.split('/').last;
           if (filename.endsWith('.woff') || filename.endsWith('.ttf')) {
             _webParamsCache[filename] = file.content as Uint8List;
           }
        }
      }
      return;
    }

    // Native: Use compute for performance
    await compute(_decodeAndExtract, {'bytes': zipBytes, 'path': targetPath});
  }

  static Future<void> _decodeAndExtract(Map<String, dynamic> args) async {
    final archive = ZipDecoder().decodeBytes(args['bytes'] as List<int>);
    final String targetPath = args['path'] as String;
    
    final targetDir = Directory(targetPath);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final flatName = filename.split('/').last;
        if (flatName.isNotEmpty && (flatName.endsWith('.woff') || flatName.endsWith('.ttf'))) {
             File('$targetPath/$flatName')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
        }
      }
    }
  }

  // --- Individual Loading ---

  /// تحميل خط صفحة محددة
  static Future<bool> loadPageFont(int pageNumber) async {
    final fontName = 'QCF4_${pageNumber.toString().padLeft(3, '0')}';
    
    if (_loadedFonts[fontName] == true) return true;
    
    try {
      final fontData = await _downloadOrGetCachedFont(fontName);
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      _fontLoaders[fontName] = fontLoader;
      _loadedFonts[fontName] = true;
      return true;
    } catch (e) {
      debugPrint('Error loading font $fontName: $e');
      return false;
    }
  }

  static Future<Uint8List> _downloadOrGetCachedFont(String fontName) async {
    // WEB SPECIFIC HANDLING
    if (kIsWeb) {
      final fileNameFull = '$fontName.woff';
      // 1. Check in-memory cache (populated by Bulk Download)
      if (_webParamsCache.containsKey(fileNameFull)) {
        return _webParamsCache[fileNameFull]!;
      }
      
      // 2. Fallback to direct download if not in bulk cache
      // Use CORS Proxy to bypass GitHub restriction on Web
      final targetUrl = '$_baseUrl/$fontName.woff';
      final url = 'https://corsproxy.io/?' + Uri.encodeComponent(targetUrl);
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to download font (Web)');
      
      // Cache it for this session
      _webParamsCache[fileNameFull] = response.bodyBytes;
      return response.bodyBytes;
    }

    // NATIVE HANDLING
    try {
        final dir = await getApplicationDocumentsDirectory();
        final bulkFile = File('${dir.path}/fonts/qcf4/$fontName.woff');
        if (await bulkFile.exists()) return await bulkFile.readAsBytes();

        final legacyFile = File('${dir.path}/fonts/$fontName.woff');
        if (await legacyFile.exists()) return await legacyFile.readAsBytes();
    } catch (e) {
        debugPrint('Error accessing fs: $e');
    }
    
    // 3. Download (Fallback)
    final url = '$_baseUrl/$fontName.woff';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to download font');
    
    final fontData = response.bodyBytes;
    await _cacheFont(fontName, fontData);
    return fontData;
  }
  
  static Future<void> _cacheFont(String fontName, Uint8List data) async {
    if (kIsWeb) {
       _webParamsCache['$fontName.woff'] = data;
       return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/fonts/qcf4');
      if (!await fontsDir.exists()) await fontsDir.create(recursive: true);
      
      final file = File('${fontsDir.path}/$fontName.woff');
      await file.writeAsBytes(data);
    } catch (e) {
      debugPrint('Error caching font: $e');
    }
  }

  /// تحميل خط البسملة
  static Future<bool> loadBasmalaFont() async {
    const fontName = 'QCF4_BSML';
    if (_loadedFonts[fontName] == true) return true;
    
    try {
      final fontData = await _downloadOrGetCachedFont(fontName);
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      _fontLoaders[fontName] = fontLoader;
      _loadedFonts[fontName] = true;
      return true;
    } catch (e) {
      debugPrint('Error loading Basmala font: $e');
      return false;
    }
  }

  /// التحقق من تحميل خط
  static bool isFontLoaded(int pageNumber) {
    final fontName = 'QCF4_${pageNumber.toString().padLeft(3, '0')}';
    return _loadedFonts[fontName] == true;
  }
  
  /// مسح Cache الخطوط
  static Future<void> clearCache() async {
    if (kIsWeb) {
        _webParamsCache.clear();
        _loadedFonts.clear();
        _fontLoaders.clear();
        return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Clear new structure
      final fontsDir = Directory('${dir.path}/fonts/qcf4');
      if (await fontsDir.exists()) await fontsDir.delete(recursive: true);
      
      // Clear legacy
      final legacyDir = Directory('${dir.path}/fonts');
      if (await legacyDir.exists()) await legacyDir.delete(recursive: true);
      
      _loadedFonts.clear();
      _fontLoaders.clear();
    } catch (e) {
      debugPrint('Error clearing font cache: $e');
    }
  }
  
  /// الحصول على حجم Cache
  static Future<int> getCacheSize() async {
    if (kIsWeb) return _webParamsCache.length * 50 * 1024; // Approximation
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/fonts/qcf4');
      if (!await fontsDir.exists()) return 0;
      
      int totalSize = 0;
      await for (var entity in fontsDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
