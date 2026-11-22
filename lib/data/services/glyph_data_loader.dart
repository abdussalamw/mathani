import 'dart:convert';

import 'package:flutter/foundation.dart'; // For compute

import '../models/page_glyph.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// خدمة تحميل بيانات Glyphs من ملف JSON
class GlyphDataLoader {
  static List<PageGlyph>? _cachedPages;
  static Future<List<PageGlyph>>? _pending;
  static int _generation = 0;

  /// تحميل جميع الصفحات من JSON
  Future<List<PageGlyph>> loadAllPages() async {
    // إذا كانت البيانات محملة مسبقاً، نرجعها مباشرة
    if (_cachedPages != null) {
      return _cachedPages!;
    }

    final pending = _pending ??= _load(_generation);
    try {
      return await pending;
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  Future<List<PageGlyph>> _load(int generation) async {
    try {
      // تحميل ملف JSON
      String jsonString;

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDir.path}/fonts/qcf4/quran_glyphs.json');

        if (await localFile.exists()) {
          jsonString = await localFile.readAsString();
        } else {
          // If the file doesn't exist, we can't fall back to assets because we removed them
          throw Exception(
            'ملفات المصحف غير موجودة. يرجى تحميلها من الإعدادات.',
          );
        }
      } else {
        // For web, if we don't have it in assets, we might need a different strategy,
        // but since we removed it from assets, it will fail anyway.
        throw Exception(
          'ملفات المصحف غير مدعومة حالياً على الويب بدون التحميل مسبقاً.',
        );
      }

      // استخدام compute للمعالجة في خلفية التطبيق (Isolates)
      // لمنع تجمد الواجهة (Stutter)
      final pages = await compute(_parseGlyphs, jsonString);
      if (generation != _generation) return await loadAllPages();
      _cachedPages = pages;
      return pages;
    } catch (e) {
      throw Exception('فشل تحميل بيانات المصحف: $e');
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

    return pages
        .where((p) => p.page >= startPage && p.page <= endPage)
        .toList();
  }

  /// الحصول على عدد الصفحات الإجمالي
  Future<int> getTotalPages() async {
    final pages = await loadAllPages();
    return pages.length;
  }

  /// مسح الذاكرة المؤقتة
  void clearCache() {
    _generation++;
    _pending = null;
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
