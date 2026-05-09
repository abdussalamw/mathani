import 'dart:convert';
import 'dart:io';

void main() async {
  final layoutFile = File('assets/data/qpc_v1_layout.json');
  final glyphsFile = File('assets/data/qpc_v1_glyphs.json');
  
  if (!layoutFile.existsSync() || !glyphsFile.existsSync()) {
    print('Files not found');
    return;
  }
  
  final layoutMap = jsonDecode(await layoutFile.readAsString()) as Map;
  final glyphsMap = jsonDecode(await glyphsFile.readAsString()) as Map;
  
  // page 461, line 3 (index 2)
  final pageLines = layoutMap['461'] as List;
  final line3Words = pageLines[2] as List; // Satar 3 is index 2
  
  print('Words on page 461, line 3:');
  int index = 1;
  String fullText = '';
  
  for (var w in line3Words) {
    if (w['w'] == null) continue; // skip non-word elements like surah headers if any
    
    final key = "${w['s']}:${w['a']}:${w['w']}";
    final glyph = glyphsMap[key];
    
    if (glyph != null) {
      final code = glyph['text'] as String;
      print("Word $index ($key): Char = $code");
      
      // Stop after 7 words
      if (index <= 7) {
        fullText += code;
      }
    } else {
      print("Word $index ($key): Not found in glyphs");
    }
    index++;
  }
  
  print('---');
  print('The first 7 words are:');
  print(fullText);
}
