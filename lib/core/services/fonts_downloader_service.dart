import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontsDownloaderService {
  static final FontsDownloaderService _instance = FontsDownloaderService._internal();
  static FontsDownloaderService get instance => _instance;
  
  FontsDownloaderService._internal();
  
  final Dio _dio = Dio();
  
  // رابط الـ Release من GitHub
  static const String fontsReleaseUrl = 
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/fonts.zip';
  
  // مفتاح التخزين للتحقق من التحميل
  static const String _fontsDownloadedKey = 'fonts_downloaded';
  static const String _fontsVersionKey = 'fonts_version';
  static const String currentVersion = '1.0';
  
  /// التحقق من وجود الخطوط محلياً
  Future<bool> areFontsDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final isDownloaded = prefs.getBool(_fontsDownloadedKey) ?? false;
    final version = prefs.getString(_fontsVersionKey) ?? '';
    
    // تحقق من الإصدار أيضاً
    return isDownloaded && version == currentVersion;
  }
  
  /// تحميل الخطوط من GitHub
  Future<bool> downloadFonts({
    Function(double progress)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('جاري الاتصال بالخادم...');
      
      // الحصول على مسار التخزين
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/fonts');
      
      // إنشاء المجلد إن لم يكن موجوداً
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }
      
      final zipPath = '${appDir.path}/fonts.zip';
      
      onStatusUpdate?.call('جاري تحميل الخطوط...');
      
      // تحميل ملف ZIP
      await _dio.download(
        fontsReleaseUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100);
            onProgress?.call(progress);
          }
        },
      );
      
      onStatusUpdate?.call('جاري فك ضغط الخطوط...');
      
      // قراءة ملف ZIP
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // فك الضغط
      int extractedCount = 0;
      for (final file in archive) {
        final filename = file.name;
        
        if (file.isFile) {
          final data = file.content as List<int>;
          final outputFile = File('${fontsDir.path}/$filename');
          
          // إنشاء المجلدات الفرعية إن لزم
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(data);
          
          extractedCount++;
          onStatusUpdate?.call('تم فك ضغط $extractedCount/${archive.length} ملف');
        }
      }
      
      // حذف ملف ZIP بعد الفك
      await File(zipPath).delete();
      
      // حفظ حالة التحميل
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fontsDownloadedKey, true);
      await prefs.setString(_fontsVersionKey, currentVersion);
      
      onStatusUpdate?.call('تم تحميل الخطوط بنجاح! ✓');
      
      return true;
    } catch (e) {
      debugPrint('خطأ في تحميل الخطوط: $e');
      onStatusUpdate?.call('فشل التحميل: $e');
      return false;
    }
  }
  
  /// الحصول على مسار الخط المحلي
  Future<String> getFontPath(String fontName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/fonts/$fontName';
  }
  
  /// الحصول على مسار خط QCF2 حسب رقم الصفحة
  Future<String> getQCF2FontPath(int page) async {
    // خط QCF2 منظم حسب الصفحات (QCF_P001.ttf ... QCF_P604.ttf)
    final pageStr = page.toString().padLeft(3, '0');
    return await getFontPath('qcf2/QCF_P$pageStr.ttf');
  }
  
  /// حذف الخطوط (لإعادة التحميل)
  Future<void> deleteFonts() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/fonts');
      
      if (await fontsDir.exists()) {
        await fontsDir.delete(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fontsDownloadedKey);
      await prefs.remove(_fontsVersionKey);
    } catch (e) {
      debugPrint('خطأ في حذف الخطوط: $e');
    }
  }
  
  /// حساب حجم الخطوط المحملة
  Future<double> getFontsSizeInMB() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/fonts');
      
      if (!await fontsDir.exists()) {
        return 0.0;
      }
      
      int totalSize = 0;
      await for (var entity in fontsDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize / (1024 * 1024); // تحويل إلى MB
    } catch (e) {
      return 0.0;
    }
  }
}
