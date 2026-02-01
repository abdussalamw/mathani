import 'dart:io';
import 'dart:convert';

/// Script to merge glyph codes from existing JSON with new ordered structure
void main() async {
  print('🔄 Merging glyph codes with ordered structure...\n');
  
  // Read ordered structure (without codes)
  final orderedFile = File('assets/data/qcf4_pages_ordered.json');
  if (!orderedFile.existsSync()) {
    print('❌ Error: qcf4_pages_ordered.json not found');
    exit(1);
  }
  
  // Read existing data (with codes)
  final existingFile = File('assets/data/qcf4_pages.json');
  if (!existingFile.existsSync()) {
    print('❌ Error: qcf4_pages.json not found');
    exit(1);
  }
  
  final orderedData = jsonDecode(await orderedFile.readAsString()) as List;
  final existingData = jsonDecode(await existingFile.readAsString()) as List;
  
  print('📄 Ordered pages: ${orderedData.length}');
  print('📄 Existing pages: ${existingData.length}\n');
  
  // Create lookup map for existing glyphs by word_id
  final Map<String, String> glyphCodes = {};
  
  for (final page in existingData) {
    final lines = page['lines'] as List;
    for (final line in lines) {
      final glyphs = line['glyphs'] as List;
      for (final glyph in glyphs) {
        final wordId = glyph['word_id'];
        final code = glyph['code'] as String;
        final type = glyph['type'] as int;
        
        if (wordId != null && code.isNotEmpty) {
          glyphCodes['${type}_$wordId'] = code;
        }
      }
    }
  }
  
  print('📚 Found ${glyphCodes.length} glyph codes\n');
  
  // Merge codes into ordered structure
  int mergedCount = 0;
  int missingCount = 0;
  
  for (final page in orderedData) {
    final lines = page['lines'] as List;
    for (final line in lines) {
      final glyphs = line['glyphs'] as List;
      for (final glyph in glyphs) {
        final wordId = glyph['word_id'];
        final type = glyph['type'] as int;
        
        if (wordId != null) {
          final key = '${type}_$wordId';
          if (glyphCodes.containsKey(key)) {
            glyph['code'] = glyphCodes[key];
            mergedCount++;
          } else {
            missingCount++;
          }
        }
      }
    }
  }
  
  print('✅ Merged $mergedCount glyph codes');
  print('⚠️  Missing $missingCount codes\n');
  
  // Write final merged JSON
  final outputFile = File('assets/data/qcf4_pages_final.json');
  final jsonOutput = JsonEncoder.withIndent('  ').convert(orderedData);
  await outputFile.writeAsString(jsonOutput);
  
  print('✨ Successfully created: ${outputFile.path}');
  print('\n🎉 Merge complete!\n');
}
