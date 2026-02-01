import 'dart:convert';
import 'dart:io';

/// سكريبت لملء أكواد QCF4 بناءً على word_id
/// 
/// خطوط QCF4 تستخدم Private Use Area في Unicode:
/// - الكلمات: U+E000 + word_id
/// - البسملة: U+FDFD
/// - نهاية الآية: U+06DD
/// - علامات التجويد: U+06D6 - U+06DC

void main() async {
  print('بدء معالجة ملف quran_glyphs.json...');
  
  // قراءة الملف
  final file = File('C:/Projects/New app/mathani/assets/data/quran_glyphs.json');
  if (!await file.exists()) {
    print('الملف غير موجود!');
    return;
  }
  
  final jsonString = await file.readAsString();
  final List<dynamic> pages = jsonDecode(jsonString);
  
  int totalGlyphs = 0;
  int filledGlyphs = 0;
  
  // معالجة كل صفحة
  for (var page in pages) {
    for (var line in page['lines']) {
      for (var glyph in line['glyphs']) {
        totalGlyphs++;
        
        // إذا كان الكود فارغاً، نملأه
        if (glyph['code'] == null || glyph['code'] == '') {
          final type = glyph['type'] as int;
          
          switch (type) {
            case 1: // كلمة
              final wordId = glyph['word_id'] as int?;
              if (wordId != null) {
                // QCF4 يستخدم Private Use Area: U+E000 + word_id
                glyph['code'] = String.fromCharCode(0xE000 + wordId);
                filledGlyphs++;
              }
              break;
              
            case 2: // نهاية آية
              glyph['code'] = '\u06DD'; // ۝
              filledGlyphs++;
              break;
              
            case 3: // علامة تجويد
              glyph['code'] = '\u06DB'; // ۛ
              filledGlyphs++;
              break;
              
            case 4: // سجدة
              glyph['code'] = '\u06E9'; // ۩
              filledGlyphs++;
              break;
              
            case 6: // بسملة
              glyph['code'] = '\uFDFD'; // ﷽
              filledGlyphs++;
              break;
              
            case 8: // اسم سورة
              final surah = glyph['sura'] as int?;
              if (surah != null) {
                // استخدام رمز خاص لاسم السورة
                glyph['code'] = String.fromCharCode(0xF000 + surah);
                filledGlyphs++;
              }
              break;
          }
        }
      }
    }
  }
  
  print('تمت معالجة $totalGlyphs رمز');
  print('تم ملء $filledGlyphs رمز فارغ');
  
  // حفظ الملف المحدث
  final outputFile = File('C:/Projects/New app/mathani/assets/data/quran_glyphs_filled.json');
  await outputFile.writeAsString(jsonEncode(pages));
  
  print('تم حفظ الملف المحدث في: ${outputFile.path}');
  print('الحجم: ${(await outputFile.length() / 1024 / 1024).toStringAsFixed(2)} MB');
}
