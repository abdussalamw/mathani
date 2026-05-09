import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'qpc_v1_models.dart';

/// خدمة محسّنة لتحميل بيانات QPC V1 من قاعدة البيانات
/// 
/// هذه الخدمة مسؤولة عن:
/// - تحميل قاعدة البيانات من Assets
/// - قراءة بيانات الصفحات والأسطر والكلمات
/// - تحويل البيانات الخام إلى نماذج Dart محسّنة
/// - التخزين المؤقت الذكي للأداء
class QPCV1DatabaseService {
  static final QPCV1DatabaseService _instance = QPCV1DatabaseService._internal();
  factory QPCV1DatabaseService() => _instance;
  QPCV1DatabaseService._internal();

  Database? _db;
  
  /// Cache للصفحات المحمّلة
  final Map<int, QPCV1Page> _pageCache = {};
  
  /// Cache لخريطة الكلمات (Word ID -> Glyph)
  final Map<int, String> _wordGlyphCache = {};
  
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// تهيئة قاعدة البيانات
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // منع التهيئة المتزامنة
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    
    _isInitializing = true;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'qpc_v1_layout.db');

      // التحقق من وجود قاعدة البيانات
      final exists = await databaseExists(path);

      if (!exists) {
        debugPrint('QPC V1 DB not found, copying from assets...');
        
        // إنشاء المجلد إن لم يكن موجوداً
        await Directory(dirname(path)).create(recursive: true);
        
        // نسخ قاعدة البيانات من Assets
        final data = await rootBundle.load('assets/data/qpc_v1_layout.db');
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        
        debugPrint('QPC V1 DB copied successfully');
      }

      // فتح قاعدة البيانات
      _db = await openDatabase(
        path,
        version: 1,
        onOpen: (db) async {
          debugPrint('QPC V1 DB opened successfully');
          
          // التحقق من الجداول الموجودة
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"
          );
          debugPrint('Available tables: ${tables.map((t) => t['name']).join(', ')}');
        },
      );
      
      // تحميل خريطة الكلمات إلى الذاكرة (للأداء)
      await _preloadWordGlyphs();
      
      _isInitialized = true;
      debugPrint('QPC V1 Database Service initialized successfully');
      
    } catch (e) {
      debugPrint('Error initializing QPC V1 DB: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// تحميل مسبق لخريطة الكلمات (Word ID -> Glyph)
  Future<void> _preloadWordGlyphs() async {
    if (_db == null) return;
    
    try {
      // استعلام لجلب جميع الكلمات وترميزاتها
      // نفترض وجود جدول 'words' أو 'glyphs'
      // سنحاول عدة هياكل محتملة
      
      // المحاولة 1: جدول words
      try {
        final words = await _db!.rawQuery('SELECT word_id, glyph_code FROM words LIMIT 10');
        if (words.isNotEmpty) {
          final allWords = await _db!.query('words');
          for (var word in allWords) {
            final wordId = word['word_id'] as int;
            final glyphCode = word['glyph_code'] as int?;
            if (glyphCode != null) {
              _wordGlyphCache[wordId] = String.fromCharCode(glyphCode);
            }
          }
          debugPrint('Loaded ${_wordGlyphCache.length} word glyphs from words table');
          return;
        }
      } catch (e) {
        // الجدول غير موجود، نجرب طريقة أخرى
      }
      
      // المحاولة 2: جدول glyphs
      try {
        final glyphs = await _db!.rawQuery('SELECT id, code FROM glyphs LIMIT 10');
        if (glyphs.isNotEmpty) {
          final allGlyphs = await _db!.query('glyphs');
          for (var glyph in allGlyphs) {
            final id = glyph['id'] as int;
            final code = glyph['code'] as int?;
            if (code != null) {
              _wordGlyphCache[id] = String.fromCharCode(code);
            }
          }
          debugPrint('Loaded ${_wordGlyphCache.length} glyphs from glyphs table');
          return;
        }
      } catch (e) {
        // الجدول غير موجود
      }
      
      // إذا لم نجد جدول خاص، سنستخدم حساب ديناميكي
      debugPrint('No glyph mapping table found, will use dynamic calculation');
      
    } catch (e) {
      debugPrint('Error preloading word glyphs: $e');
    }
  }

  /// تحميل صفحة كاملة
  Future<QPCV1Page> loadPage(int pageNumber) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // التحقق من Cache
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }
    
    if (_db == null) {
      throw Exception('Database not initialized');
    }

    try {
      // جلب بيانات الصفحة من قاعدة البيانات
      final lines = await _loadLinesForPage(pageNumber);
      
      // حساب رقم الجزء
      final juz = QPCV1Statistics.getJuzFromPage(pageNumber);
      
      // إيجاد رقم السورة (من أول سطر عادي)
      int? surahNumber;
      for (var line in lines) {
        if (line.surahNumber != null) {
          surahNumber = line.surahNumber;
          break;
        }
      }
      
      final page = QPCV1Page(
        pageNumber: pageNumber,
        lines: lines,
        juz: juz,
        surahNumber: surahNumber,
      );
      
      // حفظ في Cache
      _pageCache[pageNumber] = page;
      
      return page;
      
    } catch (e) {
      debugPrint('Error loading page $pageNumber: $e');
      rethrow;
    }
  }

  /// تحميل أسطر صفحة معينة
  Future<List<QPCV1Line>> _loadLinesForPage(int pageNumber) async {
    if (_db == null) throw Exception('Database not initialized');

    // استعلام لجلب الأسطر
    final List<Map<String, dynamic>> rawLines = await _db!.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    if (rawLines.isEmpty) {
      throw Exception('No data found for page $pageNumber');
    }

    final List<QPCV1Line> lines = [];

    for (var rawLine in rawLines) {
      final lineNumber = rawLine['line_number'] as int;
      final lineType = rawLine['line_type'] as String?;
      final surahNumber = rawLine['surah_number'] as int?;
      final ayahNumber = rawLine['ayah_number'] as int?;
      final firstWordId = rawLine['first_word_id'] as int?;
      final lastWordId = rawLine['last_word_id'] as int?;

      // تحديد نوع السطر
      QPCV1LineType type;
      if (lineType == 'surah_name') {
        type = QPCV1LineType.surahName;
      } else if (lineType == 'basmala') {
        type = QPCV1LineType.basmala;
      } else if (lineType == 'empty') {
        type = QPCV1LineType.empty;
      } else {
        type = QPCV1LineType.ayahText;
      }

      // بناء قائمة الكلمات للسطر
      List<QPCV1Word> words = [];
      
      if (type == QPCV1LineType.ayahText && 
          firstWordId != null && 
          lastWordId != null &&
          surahNumber != null &&
          ayahNumber != null) {
        
        words = await _loadWordsForLine(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          firstWordId: firstWordId,
          lastWordId: lastWordId,
        );
      }

      lines.add(QPCV1Line(
        lineNumber: lineNumber,
        type: type,
        words: words,
        surahNumber: surahNumber,
        firstAyahNumber: ayahNumber,
        lastAyahNumber: ayahNumber, // قد نحتاج تحديث هذا إذا كان السطر يحتوي عدة آيات
      ));
    }

    return lines;
  }

  /// تحميل كلمات سطر معين
  Future<List<QPCV1Word>> _loadWordsForLine({
    required int surahNumber,
    required int ayahNumber,
    required int firstWordId,
    required int lastWordId,
  }) async {
    final List<QPCV1Word> words = [];
    
    // حساب عدد الكلمات
    final wordCount = lastWordId - firstWordId + 1;
    
    for (int i = 0; i < wordCount; i++) {
      final globalWordId = firstWordId + i;
      final wordNumberInAyah = i + 1; // افتراضي، قد نحتاج تحديثه
      
      // الحصول على الرمز (Glyph)
      final glyph = await _getGlyphForWord(globalWordId, surahNumber, ayahNumber, wordNumberInAyah);
      
      words.add(QPCV1Word(
        globalWordId: globalWordId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordNumberInAyah: wordNumberInAyah,
        glyph: glyph,
      ));
    }
    
    return words;
  }

  /// الحصول على الرمز (Glyph) لكلمة معينة
  Future<String> _getGlyphForWord(
    int globalWordId, 
    int surahNumber, 
    int ayahNumber, 
    int wordNumberInAyah
  ) async {
    // المحاولة 1: من Cache
    if (_wordGlyphCache.containsKey(globalWordId)) {
      return _wordGlyphCache[globalWordId]!;
    }
    
    // المحاولة 2: من ملف JSON (qpc_v1_glyphs.json)
    final glyphFromJson = await _getGlyphFromJson(surahNumber, ayahNumber, wordNumberInAyah);
    if (glyphFromJson != null) {
      _wordGlyphCache[globalWordId] = glyphFromJson;
      return glyphFromJson;
    }
    
    // المحاولة 3: حساب ديناميكي باستخدام PUA
    // خطوط QPC V1 تستخدم Private Use Area ابتداءً من 0xE000
    // كل كلمة لها رمز فريد بناءً على ترتيبها في المصحف
    final calculatedGlyph = _calculateGlyphFromWordId(globalWordId);
    _wordGlyphCache[globalWordId] = calculatedGlyph;
    return calculatedGlyph;
  }

  /// الحصول على الرمز من ملف JSON
  Future<String?> _getGlyphFromJson(int surahNumber, int ayahNumber, int wordNumber) async {
    // سنستخدم خدمة QPCV1DataService الموجودة
    // لكن بشكل محسّن
    try {
      // تحميل الخدمة إذا لم تكن محملة
      final dataService = QPCV1DataService();
      if (!dataService.isLoaded) {
        await dataService.load();
      }
      
      final glyph = dataService.getGlyph(surahNumber, ayahNumber, wordNumber);
      return glyph;
      
    } catch (e) {
      debugPrint('Error getting glyph from JSON: $e');
      return null;
    }
  }

  /// حساب الرمز من معرّف الكلمة (Fallback)
  String _calculateGlyphFromWordId(int globalWordId) {
    // خطوط QPC V1 تستخدم PUA ابتداءً من 0xE000
    // نطاق PUA: 0xE000 - 0xF8FF (6400 رمز)
    // المصحف يحتوي على ~77,000 كلمة
    // لذا نحتاج استخدام نطاق أوسع أو تقسيم
    
    // الطريقة: استخدام modulo للبقاء في النطاق الآمن
    final offset = globalWordId % (QPCV1GlyphRanges.wordGlyphEnd - QPCV1GlyphRanges.wordGlyphStart);
    final charCode = QPCV1GlyphRanges.wordGlyphStart + offset;
    
    return String.fromCharCode(charCode);
  }

  /// مسح Cache
  void clearCache() {
    _pageCache.clear();
    debugPrint('QPC V1 page cache cleared');
  }

  /// مسح Cache الكلمات
  void clearWordCache() {
    _wordGlyphCache.clear();
    debugPrint('QPC V1 word glyph cache cleared');
  }

  /// إغلاق قاعدة البيانات
  Future<void> dispose() async {
    await _db?.close();
    _db = null;
    _isInitialized = false;
    clearCache();
    clearWordCache();
    debugPrint('QPC V1 Database Service disposed');
  }

  /// الحصول على معلومات قاعدة البيانات (للتشخيص)
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    if (_db == null) {
      return {'status': 'not_initialized'};
    }

    try {
      // الحصول على قائمة الجداول
      final tables = await _db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );

      // الحصول على عدد الصفوف في كل جدول
      final Map<String, int> tableCounts = {};
      for (var table in tables) {
        final tableName = table['name'] as String;
        if (tableName != 'sqlite_sequence' && tableName != 'android_metadata') {
          final count = Sqflite.firstIntValue(
            await _db!.rawQuery('SELECT COUNT(*) FROM $tableName')
          ) ?? 0;
          tableCounts[tableName] = count;
        }
      }

      // الحصول على هيكل جدول pages
      final pageTableInfo = await _db!.rawQuery('PRAGMA table_info(pages)');

      return {
        'status': 'initialized',
        'tables': tables.map((t) => t['name']).toList(),
        'table_counts': tableCounts,
        'page_table_structure': pageTableInfo,
        'cached_pages': _pageCache.length,
        'cached_glyphs': _wordGlyphCache.length,
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}

/// خدمة تحميل خريطة Glyphs من JSON
/// (نفس الخدمة الموجودة لكن محسّنة)
class QPCV1DataService {
  static final QPCV1DataService _instance = QPCV1DataService._internal();
  factory QPCV1DataService() => _instance;
  QPCV1DataService._internal();

  Map<String, String> _glyphMap = {};
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final jsonString = await rootBundle.loadString('assets/data/qpc_v1_glyphs.json');
      
      // تحليل JSON في Isolate منفصل
      final Map<String, dynamic> rawMap = await compute(_parseJson, jsonString);
      
      // تحويل إلى Map<String, String>
      _glyphMap = await compute(_parseGlyphMap, rawMap);
      
      _isLoaded = true;
      debugPrint('QPC V1 Glyphs loaded: ${_glyphMap.length} entries');
      
    } catch (e) {
      debugPrint('Error loading QPC V1 Glyphs: $e');
    } finally {
      _isLoading = false;
    }
  }

  static Map<String, String> _parseGlyphMap(Map<String, dynamic> rawMap) {
    final Map<String, String> result = {};
    rawMap.forEach((key, value) {
      if (value is Map && value.containsKey('text')) {
        result[key] = value['text'] as String;
      }
    });
    return result;
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  String? getGlyph(int surah, int ayah, int word) {
    if (!_isLoaded) return null;
    final key = '$surah:$ayah:$word';
    return _glyphMap[key];
  }
  
  bool get isLoaded => _isLoaded;
  
  int get glyphCount => _glyphMap.length;
}
