import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// خدمة محسّنة لتحميل خطوط QPC V1
/// 
/// هذه الخدمة توفر:
/// - تحميل ذكي للخطوط (Lazy Loading)
/// - دعم Web و Native
/// - Cache محسّن
/// - معالجة الأخطاء الشاملة
class QPCV1FontService {
  static final QPCV1FontService _instance = QPCV1FontService._internal();
  factory QPCV1FontService() => _instance;
  QPCV1FontService._internal();

  static const String _baseUrl = 
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets';
  static const int _totalPages = 604;
  
  /// الخطوط المحملة في Flutter Engine
  final Set<int> _loadedPages = {};
  
  /// FontLoaders النشطة
  final Map<int, FontLoader> _fontLoaders = {};
  
  /// Cache للخطوط في الذاكرة (للـ Web)
  final Map<String, Uint8List> _fontBytesCache = {};
  
  /// الصفحات قيد التحميل حالياً (لمنع التحميل المكرر)
  final Set<int> _loadingPages = {};

  /// تحميل خط صفحة معينة
  /// 
  /// Returns: true إذا تم التحميل بنجاح، false خلاف ذلك
  Future<bool> loadPageFont(int pageNumber) async {
    // التحقق من الصحة
    if (pageNumber < 1 || pageNumber > _totalPages) {
      debugPrint('Invalid page number: $pageNumber');
      return false;
    }
    
    // التحقق من التحميل المسبق
    if (_loadedPages.contains(pageNumber)) {
      return true;
    }
    
    // التحقق من التحميل الجاري
    if (_loadingPages.contains(pageNumber)) {
      // الانتظار حتى ينتهي التحميل
      while (_loadingPages.contains(pageNumber)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _loadedPages.contains(pageNumber);
    }
    
    // بدء التحميل
    _loadingPages.add(pageNumber);
    
    try {
      final fontFamily = _getFontFamily(pageNumber);
      final fontBytes = await _getFontBytes(pageNumber);
      
      // إنشاء FontLoader
      final fontLoader = FontLoader(fontFamily);
      fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      
      // تحميل الخط في Flutter Engine
      await fontLoader.load();
      
      // حفظ في Cache
      _fontLoaders[pageNumber] = fontLoader;
      _loadedPages.add(pageNumber);
      
      debugPrint('Font loaded successfully for page $pageNumber: $fontFamily');
      return true;
      
    } catch (e) {
      debugPrint('Error loading font for page $pageNumber: $e');
      return false;
    } finally {
      _loadingPages.remove(pageNumber);
    }
  }

  /// الحصول على bytes الخط
  Future<Uint8List> _getFontBytes(int pageNumber) async {
    final fileName = _getFontFileName(pageNumber);
    
    // المحاولة 1: من Cache الذاكرة
    if (_fontBytesCache.containsKey(fileName)) {
      return _fontBytesCache[fileName]!;
    }
    
    // المحاولة 2: من التخزين المحلي (Native فقط)
    if (!kIsWeb) {
      try {
        final localFile = await _getLocalFontFile(pageNumber);
        if (localFile != null && await localFile.exists()) {
          final bytes = await localFile.readAsBytes();
          _fontBytesCache[fileName] = bytes;
          return bytes;
        }
      } catch (e) {
        debugPrint('Error reading local font file: $e');
      }
    }
    
    // المحاولة 3: التحميل من الإنترنت
    final bytes = await _downloadFont(pageNumber);
    
    // حفظ محلياً (Native فقط)
    if (!kIsWeb) {
      try {
        await _saveFontLocally(pageNumber, bytes);
      } catch (e) {
        debugPrint('Error saving font locally: $e');
      }
    }
    
    // حفظ في Cache الذاكرة
    _fontBytesCache[fileName] = bytes;
    
    return bytes;
  }

  /// تحميل الخط من الإنترنت
  Future<Uint8List> _downloadFont(int pageNumber) async {
    final fileName = _getFontFileName(pageNumber);
    final url = '$_baseUrl/$fileName';
    
    debugPrint('Downloading font from: $url');
    
    try {
      // استخدام CORS Proxy للـ Web
      final targetUrl = kIsWeb 
          ? 'https://corsproxy.io/?' + Uri.encodeComponent(url)
          : url;
      
      final response = await http.get(Uri.parse(targetUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      throw Exception('Failed to download font: $e');
    }
  }

  /// الحصول على ملف الخط المحلي
  Future<File?> _getLocalFontFile(int pageNumber) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _getFontFileName(pageNumber);
      
      // محاولة عدة مسارات محتملة
      final paths = [
        '${dir.path}/mushafs/madani_old_v1/$fileName',
        '${dir.path}/fonts/qpc_v1/$fileName',
        '${dir.path}/fonts/$fileName',
      ];
      
      for (var path in paths) {
        final file = File(path);
        if (await file.exists()) {
          return file;
        }
      }
      
      return null;
      
    } catch (e) {
      debugPrint('Error getting local font file: $e');
      return null;
    }
  }

  /// حفظ الخط محلياً
  Future<void> _saveFontLocally(int pageNumber, Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts/qpc_v1');
      
      if (!await fontDir.exists()) {
        await fontDir.create(recursive: true);
      }
      
      final fileName = _getFontFileName(pageNumber);
      final file = File('${fontDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      debugPrint('Font saved locally: ${file.path}');
      
    } catch (e) {
      debugPrint('Error saving font locally: $e');
      rethrow;
    }
  }

  /// الحصول على اسم ملف الخط
  String _getFontFileName(int pageNumber) {
    final paddedNumber = pageNumber.toString().padLeft(3, '0');
    return 'qpc_page_$paddedNumber.ttf';
  }

  /// الحصول على اسم عائلة الخط في Flutter
  String _getFontFamily(int pageNumber) {
    return 'QPC_V1_$pageNumber';
  }

  /// الحصول على اسم عائلة الخط لصفحة معينة (للاستخدام الخارجي)
  String getFontFamilyForPage(int pageNumber) {
    return _getFontFamily(pageNumber);
  }

  /// التحقق من تحميل خط صفحة معينة
  bool isPageFontLoaded(int pageNumber) {
    return _loadedPages.contains(pageNumber);
  }

  /// تحميل مسبق لمجموعة من الصفحات (للأداء)
  Future<void> preloadPages(List<int> pageNumbers) async {
    final futures = pageNumbers.map((page) => loadPageFont(page));
    await Future.wait(futures);
  }

  /// تحميل مسبق للصفحات المحيطة بصفحة معينة
  Future<void> preloadSurroundingPages(int currentPage, {int range = 2}) async {
    final pagesToLoad = <int>[];
    
    for (int i = -range; i <= range; i++) {
      final page = currentPage + i;
      if (page >= 1 && page <= _totalPages && !_loadedPages.contains(page)) {
        pagesToLoad.add(page);
      }
    }
    
    if (pagesToLoad.isNotEmpty) {
      debugPrint('Preloading pages: $pagesToLoad');
      await preloadPages(pagesToLoad);
    }
  }

  /// مسح Cache الخطوط من الذاكرة
  void clearMemoryCache() {
    _fontBytesCache.clear();
    debugPrint('QPC V1 font memory cache cleared');
  }

  /// مسح جميع الخطوط المحلية
  Future<void> clearLocalCache() async {
    if (kIsWeb) {
      clearMemoryCache();
      return;
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      final paths = [
        '${dir.path}/fonts/qpc_v1',
        '${dir.path}/fonts',
        '${dir.path}/mushafs/madani_old_v1',
      ];
      
      for (var path in paths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          debugPrint('Deleted: $path');
        }
      }
      
      _loadedPages.clear();
      _fontLoaders.clear();
      clearMemoryCache();
      
      debugPrint('QPC V1 local font cache cleared');
      
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
    }
  }

  /// حساب حجم Cache المحلي
  Future<int> getLocalCacheSize() async {
    if (kIsWeb) {
      // تقدير تقريبي بناءً على الخطوط المحملة في الذاكرة
      return _fontBytesCache.values.fold(0, (sum, bytes) => sum + bytes.length);
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts/qpc_v1');
      
      if (!await fontDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (var entity in fontDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
      
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// الحصول على إحصائيات الخدمة
  Map<String, dynamic> getStatistics() {
    return {
      'total_pages': _totalPages,
      'loaded_pages': _loadedPages.length,
      'loading_pages': _loadingPages.length,
      'cached_fonts_memory': _fontBytesCache.length,
      'active_font_loaders': _fontLoaders.length,
      'loaded_page_numbers': _loadedPages.toList()..sort(),
    };
  }

  /// إعادة تعيين الخدمة
  void reset() {
    _loadedPages.clear();
    _fontLoaders.clear();
    _fontBytesCache.clear();
    _loadingPages.clear();
    debugPrint('QPC V1 Font Service reset');
  }
}
