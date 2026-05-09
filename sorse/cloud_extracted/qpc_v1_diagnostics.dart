import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'qpc_v1_database_service.dart';
import 'qpc_v1_font_service.dart';

/// أداة تشخيص شاملة لنظام QPC V1
/// 
/// تساعد في:
/// - اكتشاف المشاكل الشائعة
/// - التحقق من سلامة الملفات
/// - عرض معلومات تفصيلية للتشخيص
class QPCV1Diagnostics {
  static final QPCV1Diagnostics _instance = QPCV1Diagnostics._internal();
  factory QPCV1Diagnostics() => _instance;
  QPCV1Diagnostics._internal();

  /// تشغيل فحص شامل
  Future<DiagnosticReport> runFullDiagnostics() async {
    final report = DiagnosticReport();
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('  بدء التشخيص الشامل لنظام QPC V1');
    debugPrint('═══════════════════════════════════════');
    
    // 1. فحص البيئة
    await _checkEnvironment(report);
    
    // 2. فحص قاعدة البيانات
    await _checkDatabase(report);
    
    // 3. فحص ملف Glyphs
    await _checkGlyphsFile(report);
    
    // 4. فحص الخطوط
    await _checkFonts(report);
    
    // 5. فحص الأداء
    await _checkPerformance(report);
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('  انتهى التشخيص');
    debugPrint('  النتيجة: ${report.isHealthy ? "✅ صحي" : "❌ توجد مشاكل"}');
    debugPrint('═══════════════════════════════════════');
    
    return report;
  }

  /// فحص البيئة
  Future<void> _checkEnvironment(DiagnosticReport report) async {
    debugPrint('\n📱 فحص البيئة...');
    
    try {
      // التحقق من المنصة
      final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
      report.addCheck(
        'Platform',
        platform,
        true,
        'Platform: $platform',
      );
      
      // التحقق من الذاكرة المتاحة (Native فقط)
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final stat = await FileStat.stat(dir.path);
        report.addCheck(
          'Storage Access',
          dir.path,
          stat.type != FileSystemEntityType.notFound,
          'Can access: ${dir.path}',
        );
      }
      
      debugPrint('  ✓ فحص البيئة مكتمل');
      
    } catch (e) {
      report.addCheck(
        'Environment',
        'Error',
        false,
        'خطأ في فحص البيئة: $e',
      );
      debugPrint('  ✗ خطأ في فحص البيئة: $e');
    }
  }

  /// فحص قاعدة البيانات
  Future<void> _checkDatabase(DiagnosticReport report) async {
    debugPrint('\n💾 فحص قاعدة البيانات...');
    
    try {
      final dbService = QPCV1DatabaseService();
      
      // محاولة التهيئة
      await dbService.initialize();
      report.addCheck(
        'DB Initialization',
        'Success',
        true,
        'قاعدة البيانات تمت تهيئتها بنجاح',
      );
      
      // جلب معلومات قاعدة البيانات
      final info = await dbService.getDatabaseInfo();
      
      if (info['status'] == 'initialized') {
        // التحقق من الجداول
        final tables = info['tables'] as List<dynamic>? ?? [];
        final hasPages = tables.contains('pages');
        
        report.addCheck(
          'DB Tables',
          tables.join(', '),
          hasPages,
          hasPages ? 'الجداول موجودة' : 'جدول pages غير موجود',
        );
        
        // التحقق من عدد السجلات
        final tableCounts = info['table_counts'] as Map<String, dynamic>? ?? {};
        final pageCount = tableCounts['pages'] ?? 0;
        
        report.addCheck(
          'Page Records',
          pageCount.toString(),
          pageCount > 0,
          'عدد السجلات في جدول pages: $pageCount',
        );
        
        // محاولة تحميل صفحة
        try {
          final page1 = await dbService.loadPage(1);
          report.addCheck(
            'Page Loading',
            '${page1.lines.length} lines',
            page1.lines.isNotEmpty,
            'تم تحميل صفحة 1 بنجاح: ${page1.lines.length} سطر',
          );
        } catch (e) {
          report.addCheck(
            'Page Loading',
            'Failed',
            false,
            'فشل تحميل الصفحة: $e',
          );
        }
        
      } else {
        report.addCheck(
          'DB Status',
          info['status'].toString(),
          false,
          'قاعدة البيانات غير متاحة: ${info['status']}',
        );
      }
      
      debugPrint('  ✓ فحص قاعدة البيانات مكتمل');
      
    } catch (e) {
      report.addCheck(
        'Database',
        'Error',
        false,
        'خطأ في فحص قاعدة البيانات: $e',
      );
      debugPrint('  ✗ خطأ في فحص قاعدة البيانات: $e');
    }
  }

  /// فحص ملف Glyphs
  Future<void> _checkGlyphsFile(DiagnosticReport report) async {
    debugPrint('\n📝 فحص ملف Glyphs...');
    
    try {
      final dataService = QPCV1DataService();
      
      await dataService.load();
      
      final glyphCount = dataService.glyphCount;
      report.addCheck(
        'Glyphs File',
        '$glyphCount entries',
        glyphCount > 0,
        'ملف Glyphs محمّل: $glyphCount إدخال',
      );
      
      // اختبار جلب glyph
      final testGlyph = dataService.getGlyph(1, 1, 1);
      report.addCheck(
        'Glyph Access',
        testGlyph ?? 'null',
        testGlyph != null,
        testGlyph != null ? 'يمكن الوصول إلى Glyphs' : 'لا يمكن الوصول إلى Glyphs',
      );
      
      debugPrint('  ✓ فحص ملف Glyphs مكتمل');
      
    } catch (e) {
      report.addCheck(
        'Glyphs File',
        'Error',
        false,
        'خطأ في فحص ملف Glyphs: $e',
      );
      debugPrint('  ✗ خطأ في فحص ملف Glyphs: $e');
    }
  }

  /// فحص الخطوط
  Future<void> _checkFonts(DiagnosticReport report) async {
    debugPrint('\n🔤 فحص الخطوط...');
    
    try {
      final fontService = QPCV1FontService();
      
      // محاولة تحميل خط صفحة 1
      final loaded = await fontService.loadPageFont(1);
      report.addCheck(
        'Font Loading',
        loaded ? 'Success' : 'Failed',
        loaded,
        loaded ? 'تم تحميل خط صفحة 1' : 'فشل تحميل خط صفحة 1',
      );
      
      // الحصول على إحصائيات
      final stats = fontService.getStatistics();
      report.addCheck(
        'Loaded Fonts',
        '${stats['loaded_pages']}',
        stats['loaded_pages'] > 0,
        'عدد الخطوط المحملة: ${stats['loaded_pages']}',
      );
      
      // حساب حجم Cache
      final cacheSize = await fontService.getLocalCacheSize();
      final cacheSizeMB = (cacheSize / 1024 / 1024).toStringAsFixed(2);
      report.addCheck(
        'Font Cache Size',
        '$cacheSizeMB MB',
        true,
        'حجم Cache الخطوط: $cacheSizeMB MB',
      );
      
      debugPrint('  ✓ فحص الخطوط مكتمل');
      
    } catch (e) {
      report.addCheck(
        'Fonts',
        'Error',
        false,
        'خطأ في فحص الخطوط: $e',
      );
      debugPrint('  ✗ خطأ في فحص الخطوط: $e');
    }
  }

  /// فحص الأداء
  Future<void> _checkPerformance(DiagnosticReport report) async {
    debugPrint('\n⚡ فحص الأداء...');
    
    try {
      final dbService = QPCV1DatabaseService();
      final fontService = QPCV1FontService();
      
      // قياس وقت تحميل صفحة
      final stopwatch = Stopwatch()..start();
      await dbService.loadPage(2);
      await fontService.loadPageFont(2);
      stopwatch.stop();
      
      final loadTime = stopwatch.elapsedMilliseconds;
      report.addCheck(
        'Page Load Time',
        '${loadTime}ms',
        loadTime < 1000,
        loadTime < 1000 
            ? 'وقت التحميل ممتاز: ${loadTime}ms'
            : 'وقت التحميل بطيء: ${loadTime}ms',
      );
      
      debugPrint('  ✓ فحص الأداء مكتمل');
      
    } catch (e) {
      report.addCheck(
        'Performance',
        'Error',
        false,
        'خطأ في فحص الأداء: $e',
      );
      debugPrint('  ✗ خطأ في فحص الأداء: $e');
    }
  }

  /// عرض التقرير في Dialog
  static void showReport(BuildContext context, DiagnosticReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              report.isHealthy ? Icons.check_circle : Icons.error,
              color: report.isHealthy ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(report.isHealthy ? 'النظام سليم' : 'توجد مشاكل'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...report.checks.map((check) => _buildCheckTile(check)),
            ],
          ),
        ),
        actions: [
          if (!report.isHealthy)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFixSuggestions(context, report);
              },
              child: const Text('عرض الحلول'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static Widget _buildCheckTile(DiagnosticCheck check) {
    return ListTile(
      leading: Icon(
        check.passed ? Icons.check_circle : Icons.cancel,
        color: check.passed ? Colors.green : Colors.red,
      ),
      title: Text(check.name),
      subtitle: Text(check.message),
      dense: true,
    );
  }

  static void _showFixSuggestions(BuildContext context, DiagnosticReport report) {
    final suggestions = <String>[];
    
    for (var check in report.checks) {
      if (!check.passed) {
        if (check.name.contains('DB')) {
          suggestions.add('• تأكد من وجود ملف qpc_v1_layout.db في assets/data/');
          suggestions.add('• تحقق من صحة ملف قاعدة البيانات');
        }
        if (check.name.contains('Glyph')) {
          suggestions.add('• تأكد من وجود ملف qpc_v1_glyphs.json في assets/data/');
          suggestions.add('• تحقق من صحة تنسيق JSON');
        }
        if (check.name.contains('Font')) {
          suggestions.add('• تحقق من اتصال الإنترنت لتحميل الخطوط');
          suggestions.add('• جرب مسح Cache الخطوط وإعادة المحاولة');
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الحلول المقترحة'),
        content: SingleChildScrollView(
          child: Text(suggestions.isEmpty 
              ? 'لا توجد حلول متاحة'
              : suggestions.join('\n\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

/// تقرير التشخيص
class DiagnosticReport {
  final List<DiagnosticCheck> checks = [];
  
  void addCheck(String name, String value, bool passed, String message) {
    checks.add(DiagnosticCheck(
      name: name,
      value: value,
      passed: passed,
      message: message,
    ));
  }
  
  bool get isHealthy => checks.every((check) => check.passed);
  
  int get passedCount => checks.where((check) => check.passed).length;
  int get failedCount => checks.length - passedCount;
  
  @override
  String toString() {
    return 'DiagnosticReport(total: ${checks.length}, passed: $passedCount, failed: $failedCount)';
  }
}

/// فحص تشخيصي واحد
class DiagnosticCheck {
  final String name;
  final String value;
  final bool passed;
  final String message;
  
  DiagnosticCheck({
    required this.name,
    required this.value,
    required this.passed,
    required this.message,
  });
  
  @override
  String toString() {
    return '${passed ? "✓" : "✗"} $name: $value - $message';
  }
}
