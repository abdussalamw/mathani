import 'dart:io';
import 'dart:convert';

/// Script to convert TB_Glyph.csv to properly structured JSON
/// with correct ordering for QCF4 glyphs
void main() async {
  print('🔄 Starting CSV to JSON conversion...\n');
  
  final csvFile = File('scripts/TB_Glyph.csv');
  if (!csvFile.existsSync()) {
    print('❌ Error: TB_Glyph.csv not found in scripts folder');
    exit(1);
  }
  
  final lines = await csvFile.readAsLines();
  print('📄 Read ${lines.length} lines from CSV\n');
  
  // Skip header
  final dataLines = lines.skip(1);
  
  // Group by page
  final Map<int, List<Map<String, dynamic>>> pageData = {};
  
  int processedCount = 0;
  for (final line in dataLines) {
    final parts = line.split(',');
    if (parts.length < 11) continue;
    
    final pageNumber = int.tryParse(parts[8]);
    final lineNumber = int.tryParse(parts[9]);
    final order = int.tryParse(parts[10]);
    final glyphTypeId = int.tryParse(parts[3]);
    final wordId = parts[5].isEmpty ? null : int.tryParse(parts[5]);
    final suraNumber = int.tryParse(parts[6]);
    final ayahNumber = int.tryParse(parts[7]);
    
    if (pageNumber == null || lineNumber == null || order == null) continue;
    
    final glyph = {
      'type': glyphTypeId ?? 1,
      'code': '', // Will be filled from existing data
      'word_id': wordId,
      'sura': suraNumber ?? 0,
      'ayah': ayahNumber ?? 0,
      'line': lineNumber,
      'order': order,
    };
    
    pageData.putIfAbsent(pageNumber, () => []);
    pageData[pageNumber]!.add(glyph);
    
    processedCount++;
    if (processedCount % 10000 == 0) {
      print('⏳ Processed $processedCount glyphs...');
    }
  }
  
  print('\n✅ Processed $processedCount glyphs total');
  print('📊 Pages: ${pageData.length}\n');
  
  // Sort each page by order
  for (final page in pageData.values) {
    page.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  }
  
  // Group by lines within each page - using List instead of Map
  final List<Map<String, dynamic>> pagesJson = [];
  
  // Sort pages by page number
  final sortedPages = pageData.keys.toList()..sort();
  
  for (final pageNum in sortedPages) {
    final glyphs = pageData[pageNum]!;
    
    // Group by line
    final Map<int, List<Map<String, dynamic>>> lineGroups = {};
    for (final glyph in glyphs) {
      final lineNum = glyph['line'] as int;
      lineGroups.putIfAbsent(lineNum, () => []);
      lineGroups[lineNum]!.add({
        'type': glyph['type'],
        'code': '',
        'word_id': glyph['word_id'],
        'sura': glyph['sura'],
        'ayah': glyph['ayah'],
      });
    }
    
    // Create lines array
    final lines = <Map<String, dynamic>>[];
    for (int i = 1; i <= 15; i++) {
      if (lineGroups.containsKey(i)) {
        lines.add({
          'line': i,
          'glyphs': lineGroups[i],
        });
      }
    }
    
    pagesJson.add({
      'page': pageNum,
      'lines': lines,
    });
  }
  
  // Write to JSON file
  final outputFile = File('assets/data/qcf4_pages_ordered.json');
  await outputFile.parent.create(recursive: true);
  
  final jsonOutput = JsonEncoder.withIndent('  ').convert(pagesJson);
  await outputFile.writeAsString(jsonOutput);
  
  print('✨ Successfully created: ${outputFile.path}');
  print('📦 Total pages: ${pagesJson.length}');
  print('\n🎉 Conversion complete!\n');
}
