import '../../core/utils/async_work_pool.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'mushaf_package.dart';

/// خدمة تحميل خطوط QPC V1 (مصحف المدينة القديم)
class QPCV1FontDownloader {
  static final Map<String, bool> _loadedFonts = {};
  static final Map<String, FontLoader> _fontLoaders = {};

  /// التحقق مما إذا كانت جميع الخطوط موجودة
  static Future<bool> areAllFontsAvailable() async {
    if (kIsWeb) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      // Updated path to match MushafMetadataProvider's download location
      final fontsDir = Directory('${dir.path}/mushafs/madani_old_v1');

      recoverMushafDirectory(fontsDir);
      return await validMushafPackage('madani_old_v1', fontsDir);
    } catch (e) {
      return false;
    }
  }

  /// تحميل خط صفحة محددة
  static final _fontWork = AsyncWorkPool<int, bool>();

  static Future<bool> loadPageFont(int pageNumber) =>
      _fontWork.run(pageNumber, () => _loadPageFont(pageNumber));

  static Future<bool> _loadPageFont(int pageNumber) async {
    // Format: QCF_P001.woff (new) or qpc_page_001.ttf (old)
    final fontFamily = 'p$pageNumber-v1';

    // Check if already loaded in Flutter engine
    if (_loadedFonts[fontFamily] == true) return true;

    try {
      final fontData = await _downloadOrGetCachedFont(pageNumber);
      final fontLoader = FontLoader(fontFamily);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();

      _fontLoaders[fontFamily] = fontLoader;
      _loadedFonts[fontFamily] = true;
      return true;
    } catch (e) {
      debugPrint('Error loading QPC V1 font page $pageNumber: $e');
      return false;
    }
  }

  static Future<Uint8List> _downloadOrGetCachedFont(int pageNumber) async {
    // WEB SPECIFIC HANDLING
    if (kIsWeb) {
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

      // Search for WOFF first (new), then TTF (old) for backward compatibility
      final List<String> possibleNames = [
        // WOFF format (new - from ZIP)
        'QCF_P$pageNumStr.woff',
        'qcf_p$pageNumStr.woff',
        // TTF format (old - from tar.bz2)
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
            return await file.readAsBytes();
          }
        }
      }

      debugPrint('ERROR: QPC V1 font not found for page $pageNumber');
    } catch (e) {
      debugPrint('Error accessing fs: $e');
    }

    throw Exception(
      'Font file not found locally. Please download the Mushaf first.',
    );
  }

  /// Helper to get the FontFamily name for a page
  static String getFontFamily(int pageNumber) {
    return 'p$pageNumber-v1';
  }
}
