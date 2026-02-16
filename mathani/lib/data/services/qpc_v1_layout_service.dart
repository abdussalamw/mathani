import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class V1Line {
  final int lineNumber;
  final String text;
  final bool isSurahHeader;
  final bool isBasmala;
  final int? firstWordId;
  final int? lastWordId;

  V1Line({
    required this.lineNumber,
    required this.text,
    this.isSurahHeader = false,
    this.isBasmala = false,
    this.firstWordId,
    this.lastWordId,
  });
}

class QPCV1LayoutService {
  static final QPCV1LayoutService _instance = QPCV1LayoutService._internal();
  factory QPCV1LayoutService() => _instance;
  QPCV1LayoutService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "qpc_v1_layout.db");

    // Check if exists
    var exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join("assets", "data", "qpc_v1_layout.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("Error copying QPC V1 DB: $e");
      }
    }

    _db = await openDatabase(path);
  }

  Future<List<V1Line>> getLinesForPage(int pageNumber) async {
    if (_db == null) await init();

    final List<Map<String, dynamic>> maps = await _db!.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number',
    );

    List<V1Line> lines = [];
    // Identify page start word ID to normalize PUA codes
    // But wait, does the font use 1-based index from the START of the page?
    // Usually yes. First word displayed = \uE001.
    // So we need a counter that resets for the page?
    // Or does the font map Global IDs? Unlikely.
    // We assume Page-Relative 1-based PUA at 0xE001.
    
    int currentGlyphIndex = 1; 

    for (var row in maps) {
      final lineType = row['line_type'] as String;
      final lineNum = row['line_number'] as int;
      final firstWid = row['first_word_id'] as int?;
      final lastWid = row['last_word_id'] as int?;

      String text = '';
      bool isHeader = false;
      bool isBasmala = false;

      if (lineType == 'surah_name') {
        isHeader = true;
        // Surah header logic? Is it text or special glyph?
        // Usually V1 has headers as images or special text. 
        // For now, let's treat as Header flag for widget to render "Surah Frame".
        text = 'SURAH_${row['surah_number']}'; 
      } else if (lineType == 'basmala') {
        isBasmala = true;
        // Basmala is usually \uE001 if it's the first thing? 
        // Or specific strict code?
        // Or provided as text?
        // In QPC V1 DB, Basmala might be just a gap or implicit.
        // Let's assume standard Basmala string for now, or check if it has word IDs?
        // DB debug showed Basmala has NO word IDs.
        text = 'بِسْمِ ٱLlَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'; // Fallback text
      } else {
        // Ayah Line
        if (firstWid != null && lastWid != null) {
          int count = (lastWid - firstWid) + 1;
          List<String> glyphs = [];
          for (int i = 0; i < count; i++) {
            // PUA Area often starts at 0xE000 or 0xF000.
            // QPC usually uses 0xE001 + index.
            // Index is 0-based from start of PAGE?
            int charCode = 0xE000 + currentGlyphIndex; 
            glyphs.add(String.fromCharCode(charCode));
            currentGlyphIndex++;
          }
          text = glyphs.join(''); // No spaces for PUA fonts usually? Or spaces?
          // QPC V1 fonts usually need NO spaces or specific spacing.
          // Let's try join('') first.
        }
      }

      lines.add(V1Line(
        lineNumber: lineNum,
        text: text,
        isSurahHeader: isHeader,
        isBasmala: isBasmala,
        firstWordId: firstWid,
        lastWordId: lastWid,
      ));
    }

    return lines;
  }
}
