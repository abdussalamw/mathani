import 'dart:io';
import 'dart:convert';

/// Script to fill glyph codes in the ordered JSON
/// QCF4 uses Unicode Private Use Area (U+E000 to U+F8FF)
/// Each word has a unique code based on its word_id
void main() async {
  print('🔄 Filling glyph codes in ordered JSON...\n');
  
  final orderedFile = File('assets/data/qcf4_pages_ordered.json');
  if (!orderedFile.existsSync()) {
    print('❌ Error: qcf4_pages_ordered.json not found');
    exit(1);
  }
  
  final jsonData = jsonDecode(await orderedFile.readAsString()) as List;
  print('📄 Loaded ${jsonData.length} pages\n');
  
  int filledCount = 0;
  
  for (final page in jsonData) {
    final lines = page['lines'] as List;
    for (final line in lines) {
      final glyphs = line['glyphs'] as List;
      for (final glyph in glyphs) {
        final type = glyph['type'] as int;
        final wordId = glyph['word_id'] as int?;
        
        String code = '';
        
        switch (type) {
          case 1: // Word
            if (wordId != null) {
              // QCF4 word codes start at U+E000
              // Each word_id maps to a unique Unicode character
              final codePoint = 0xE000 + wordId;
              code = String.fromCharCode(codePoint);
            }
            break;
            
          case 2: // Ayah end marker
            final ayah = glyph['ayah'] as int?;
            if (ayah != null) {
              // Ayah end markers use specific range
              // U+06DD is Arabic end of ayah
              code = '\u06DD';
            }
            break;
            
          case 3: // Pause mark
            code = '\u06DB'; // Small high seen
            break;
            
          case 4: // Sajdah
            code = '\u06E9'; // Place of sajdah
            break;
            
          case 6: // Basmala
            code = '\uFDFD'; // Bismillah symbol
            break;
            
          case 8: // Surah name
            final sura = glyph['sura'] as int?;
            if (sura != null) {
              // Surah names use specific codes
              // Starting from U+F000
              final codePoint = 0xF000 + sura;
              code = String.fromCharCode(codePoint);
            }
            break;
        }
        
        if (code.isNotEmpty) {
          glyph['code'] = code;
          filledCount++;
        }
      }
    }
    
    if ((page['page'] as int) % 100 == 0) {
      print('⏳ Processed page ${page['page']}...');
    }
  }
  
  print('\n✅ Filled $filledCount glyph codes\n');
  
  // Write final JSON
  final outputFile = File('assets/data/qcf4_pages_final.json');
  final jsonOutput = JsonEncoder.withIndent('  ').convert(jsonData);
  await outputFile.writeAsString(jsonOutput);
  
  print('✨ Successfully created: ${outputFile.path}');
  print('\n🎉 Complete!\n');
}
