import 'dart:convert';
import 'dart:io';

void main() async {
  stdout.writeln('Starting data merge...');

  // 1. Load Simple JSON
  final simpleFile = File('assets/data/quran_simple.json');
  if (!await simpleFile.exists()) {
    stderr.writeln('Error: quran_simple.json not found');
    exit(1);
  }
  
  final simpleContent = await simpleFile.readAsString();
  final List<dynamic> chapters = json.decode(simpleContent);
  stdout.writeln('Loaded ${chapters.length} chapters from simple JSON');

  // 2. Load CSV and build Page Map
  final csvFile = File('assets/data/TB_Glyph.csv');
  if (!await csvFile.exists()) {
    stderr.writeln('Error: TB_Glyph.csv not found');
    exit(1);
  }

  // Map<SurahNum, Map<AyahNum, PageNum>>
  final Map<int, Map<int, int>> pageMap = {};
  
  final lines = await csvFile.readAsLines();
  stdout.writeln('Loaded CSV with ${lines.length} lines');

  // Skip header
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    final parts = line.split(',');
    
    // Safety check for columns
    if (parts.length < 10) continue;

    // Structure:
    // ... sura_number(idx 6), ayah_number(idx 7), page_number(idx 8), ...
    // Note: handling potential empty values due to consecutive commas
    // "88553,2,,6,,,1,,1,1,1" -> parts[6] is '1', parts[7] is ''
    
    final surahStr = parts[6];
    final ayahStr = parts[7];
    final pageStr = parts[8];

    if (surahStr.isEmpty || ayahStr.isEmpty || pageStr.isEmpty) continue;

    final surah = int.tryParse(surahStr);
    final ayah = int.tryParse(ayahStr);
    final page = int.tryParse(pageStr);

    if (surah != null && ayah != null && page != null) {
       if (!pageMap.containsKey(surah)) {
         pageMap[surah] = {};
       }
       // We only need the first occurrence (start page of the ayah)
       if (!pageMap[surah]!.containsKey(ayah)) {
         pageMap[surah]![ayah] = page;
       }
    }
  }
  stdout.writeln('Mapped pages for ${pageMap.length} surahs');

  // 3. Merge Data
  final List<Map<String, dynamic>> advancedData = [];

  for (var chapter in chapters) {
    final surahNum = chapter['id'] as int;
    final verses = chapter['verses'] as List;
    
    final newVerses = <Map<String, dynamic>>[];
    
    for (var verse in verses) {
      final ayahNum = verse['id'] as int;
      final text = verse['text'] as String;
      
      // Get Page
      int page = 1; 
      if (pageMap.containsKey(surahNum) && pageMap[surahNum]!.containsKey(ayahNum)) {
        page = pageMap[surahNum]![ayahNum]!;
      } else {
        // Fallback or explicit mapping for Surah 1? Surah 1 is Page 1.
         if (surahNum == 1) page = 1;
      }

      // Calculate Juz (Standard Madani 15-line approx)
      // Juz 1 starts page 1. Juz 2 starts page 22. Juz 30 starts page 582.
      int juz = ((page - 2) / 20).floor() + 1;
      if (juz < 1) juz = 1;
      if (juz > 30) juz = 30;

      newVerses.add({
        'id': ayahNum,
        'text': text,
        'page': page,
        'juz': juz,
      });
    }

    // Keep Surah metadata
    advancedData.add({
      'id': surahNum,
      'name': chapter['name'],
      'transliteration': chapter['transliteration'],
      'type': chapter['type'],
      'total_verses': chapter['total_verses'],
      'verses': newVerses
    });
  }

  // 4. Save
  final outputFile = File('assets/data/quran_advanced.json');
  await outputFile.writeAsString(json.encode(advancedData));
  stdout.writeln('Successfully saved quran_advanced.json');
}
