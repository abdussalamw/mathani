
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mathani/core/services/fonts_downloader_service.dart';

class QuranFontLoader {
  static final QuranFontLoader _instance = QuranFontLoader._internal();
  static QuranFontLoader get instance => _instance;
  
  QuranFontLoader._internal();
  
  // Cache للخطوط المحملة لتحسين الأداء
  final Map<int, ByteData> _fontCache = {};
  
  /// تحميل خط QCF2 لصفحة معينة
  Future<String?> loadFontForPage(int pageNumber) async {
    try {
      // الحصول على مسار الخط
      final fontPath = await FontsDownloaderService.instance
          .getQCF2FontPath(pageNumber);
      
      final fontFile = File(fontPath);
      
      if (!await fontFile.exists()) {
        print('الخط غير موجود للصفحة $pageNumber');
        return null;
      }
      
      // قراءة الخط وتسجيله
      final fontData = await fontFile.readAsBytes();
      final fontLoader = FontLoader('QCF_P${pageNumber.toString().padLeft(3, '0')}');
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      return 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      print('خطأ في تحميل الخط للصفحة $pageNumber: $e');
      return null;
    }
  }
  
  /// تحميل مجموعة من الخطوط مسبقاً (للصفحات المجاورة)
  Future<void> preloadFontsForPages(List<int> pages) async {
    for (final page in pages) {
      await loadFontForPage(page);
    }
  }
  
  /// الحصول على اسم العائلة الخطية لصفحة معينة
  String getFontFamilyForPage(int pageNumber) {
    return 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
  }
  
  /// مسح ذاكرة التخزين المؤقت
  void clearCache() {
    _fontCache.clear();
  }
}