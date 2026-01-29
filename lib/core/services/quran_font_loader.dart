
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
      print('🔍 محاولة تحميل خط للصفحة: $pageNumber');
      
      // الحصول على مسار الخط
      final fontPath = await FontsDownloaderService.instance
          .getQCF2FontPath(pageNumber);
      
      print('📁 مسار الخط: $fontPath');
      
      final fontFile = File(fontPath);
      
      if (!await fontFile.exists()) {
        print('❌ الخط غير موجود للصفحة $pageNumber في المسار: $fontPath');
        return null;
      }
      
      print('✅ الخط موجود! جاري التحميل...');
      
      // قراءة الخط وتسجيله
      final fontData = await fontFile.readAsBytes();
      final fontFamilyName = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
      final fontLoader = FontLoader(fontFamilyName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      
      print('✅ تم تحميل الخط بنجاح: $fontFamilyName');
      
      return fontFamilyName;
    } catch (e) {
      print('❌ خطأ في تحميل الخط للصفحة $pageNumber: $e');
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