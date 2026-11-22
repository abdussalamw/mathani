import '../../core/utils/async_work_pool.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

import 'mushaf_package.dart';
import 'mushaf_downloader_service.dart';
import 'glyph_data_loader.dart';
import 'qcf4_alignment_service.dart';

import 'package:flutter/foundation.dart';

/// خدمة تحميل خطوط QCF4 من GitHub
/// تدعم التحميل الفردي (Legacy) والتحميل الجماعي (Bulk)
class QCF4FontDownloader {
  static const String _baseUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets';
  static const String _zipFileName = 'quran_fonts_qfc4.zip';
  static final _installWork = AsyncWorkPool<String, void>();

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

      recoverMushafDirectory(fontsDir);
      return await validMushafPackage('qcf2_v4_woff2', fontsDir);
    } catch (e) {
      return false;
    }
  }

  /// تحميل وفك ضغط ملف الخطوط الكامل
  static Future<void> downloadAllFonts({
    required Function(double progress) onProgress,
    required Function(String status) onStatusChanged,
  }) => _installWork.run('qcf4', () async {
    if (kIsWeb) {
      final response = await http
          .get(Uri.parse('$_baseUrl/$_zipFileName'))
          .timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final archive = ZipDecoder().decodeBytes(
        response.bodyBytes,
        verify: true,
      );
      for (final entry in archive.files.where((e) => e.isFile)) {
        _webParamsCache[entry.name.split('/').last] = entry.content;
      }
      onProgress(1.0);
      return;
    }
    final docs = await getApplicationDocumentsDirectory();
    final target = Directory('${docs.path}/fonts/qcf4');
    await target.parent.create(recursive: true);
    final stage = await target.parent.createTemp('.qcf4-install-');
    try {
      onStatusChanged('جاري تحميل الخطوط والتحقق منها');
      await MushafDownloaderService.downloadAndExtract(
        url: '$_baseUrl/$_zipFileName',
        destinationPath: stage.path,
        onProgress: (p) => onProgress(p * .95),
      );
      if (!await validMushafPackage('qcf2_v4_woff2', stage)) {
        throw const FormatException('حزمة خطوط المصحف تالفة أو ناقصة');
      }
      commitMushafDirectory(stage, target);
      _loadedFonts.clear();
      _fontLoaders.clear();
      GlyphDataLoader().clearCache();
      QCF4AlignmentService().invalidate();
      onProgress(1.0);
    } finally {
      if (await stage.exists()) await stage.delete(recursive: true);
    }
  });

  // --- Individual Loading ---

  /// تحميل خط صفحة محددة
  static final _fontWork = AsyncWorkPool<int, bool>();

  static Future<bool> loadPageFont(int pageNumber) =>
      _fontWork.run(pageNumber, () => _loadPageFont(pageNumber));

  static Future<bool> _loadPageFont(int pageNumber) async {
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
      final url = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to download font (Web)');
      }

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
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
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
    return true; // مدمج في التطبيق
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
