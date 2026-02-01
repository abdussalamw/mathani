import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For compute
import '../models/page_glyph.dart';

/// خدمة تحميل بيانات Glyphs من ملف JSON
class GlyphDataLoader {
  static List<PageGlyph>? _cachedPages;
  static bool _isLoading = false;
  
  /// تحميل جميع الصفحات من JSON
  Future<List<PageGlyph>> loadAllPages() async {
    // إذا كانت البيانات محملة مسبقاً، نرجعها مباشرة
    if (_cachedPages != null) {
      return _cachedPages!;
    }
    
    // إذا كان التحميل جارياً، ننتظر
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // إذا تم التحميل أثناء الانتظار
    if (_cachedPages != null) {
      return _cachedPages!;
    }
    
    try {
      _isLoading = true;
      
      // تحميل ملف JSON
      final jsonString = await rootBundle.loadString(
        'assets/data/quran_glyphs.json'
      );
      
      // استخدام compute للمعالجة في خلفية التطبيق (Isolates) 
      // لمنع تجمد الواجهة (Stutter)
      _cachedPages = await compute(_parseGlyphs, jsonString);
      
      return _cachedPages!;
    } catch (e) {
      throw Exception('فشل تحميل بيانات المصحف: $e');
    } finally {
      _isLoading = false;
    }
  }
  
  /// تحميل صفحة محددة
  Future<PageGlyph> loadPage(int pageNumber) async {
    final pages = await loadAllPages();
    
    try {
      return pages.firstWhere((p) => p.page == pageNumber);
    } catch (e) {
      throw Exception('الصفحة رقم $pageNumber غير موجودة');
    }
  }
  
  /// تحميل مجموعة من الصفحات
  Future<List<PageGlyph>> loadPageRange(int startPage, int endPage) async {
    final pages = await loadAllPages();
    
    return pages.where((p) => p.page >= startPage && p.page <= endPage).toList();
  }
  
  /// الحصول على عدد الصفحات الإجمالي
  Future<int> getTotalPages() async {
    final pages = await loadAllPages();
    return pages.length;
  }
  
  /// مسح الذاكرة المؤقتة
  void clearCache() {
    _cachedPages = null;
  }
}

/// Helper function for compute (Must be top-level or static)
List<PageGlyph> _parseGlyphs(String jsonString) {
  final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData
      .map((pageJson) => PageGlyph.fromJson(pageJson as Map<String, dynamic>))
      .toList();
}
