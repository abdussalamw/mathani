import 'package:flutter/material.dart';
import '../../data/models/page_glyph.dart';
import '../../core/constants/app_colors.dart';

/// Widget لعرض سطر واحد من صفحة المصحف
class PageLineWidget extends StatelessWidget {
  final PageLine line;
  final int pageNumber;
  final bool isParentFontLoaded;
  final Function(int surah, int ayah)? onAyahSelected;
  final Function(int surah, int ayah)? onAyahLongPress; // Added
  final int? selectedSurah;
  final int? selectedAyah;
  
  final bool isDigital;
  final List<String>? digitalWords;
  
  const PageLineWidget({
    Key? key,
    required this.line,
    required this.pageNumber,
    required this.isParentFontLoaded,
    this.onAyahSelected,
    this.onAyahLongPress, // Added
    this.selectedSurah,
    this.selectedAyah,
    this.isDigital = false,
    this.digitalWords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If Digital Mode with available words mapping, we behave like the standard layout but with digital text.
    if (isDigital) {
       if (digitalWords == null) return Container(); // Fallback if data not ready
       
       int wordIndex = 0;
       
       return Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown, // Prevent overflow if text is too wide
            child: Row(
              mainAxisAlignment: _getLineAlignment(line), 
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: line.glyphs.map((glyph) {
                 // Determine Text Content
                 String text = '';
                 // Font Style Defaults
                 String fontFamily = 'UthmanicHafs'; // خط عثماني حفص V22
                 
                 // استخدام حجم خط متجاوب لتقليل الحاجة لتصغير السطر (FittedBox)
                 // مما يحافظ على سماكة خط موحدة بين الأسطر
                 double screenWidth = MediaQuery.of(context).size.width;
                 double fontSize = screenWidth * 0.045; // 4.5% من عرض الشاشة
                 if (fontSize > 24) fontSize = 24; // حد أقصى
                 if (fontSize < 16) fontSize = 16; // حد أدنى
                 
                 Color? color;
                 
                 if (glyph.isWord) {
                   if (wordIndex < digitalWords!.length) {
                     text = digitalWords![wordIndex];
                     wordIndex++;
                   } else {
                     text = '???';
                   }
                   // If text is empty or null, skip?
                   if (text.isEmpty) return const SizedBox();
                   
                 } else if (glyph.isAyahEnd) {
                   text = '\uFD3F${glyph.ayah?.toString() ?? ''}\uFD3E'; // عكس الأقواس للعرض الصحيح
                   fontFamily = 'UthmanicHafs';
                   color = AppColors.primary; // أحمر نسكافيه
                 } else if (glyph.isBasmala || glyph.isSurahName) {
                   // For now, simple text, or mapped specific text if passed
                   if (glyph.isBasmala) {
                      text = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
                      fontSize = 24;
                   } else if (glyph.isSurahName) {
                      text = 'سورة'; // We might need the name, but usually Surah Name is its own Frame.
                   }
                 } else {
                   return const SizedBox(); // Skip pauses/sajdahs in digital for now or handle them
                 }

                 final isSelected = selectedSurah != null && 
                                     selectedAyah != null &&
                                     glyph.surah == selectedSurah && 
                                     glyph.ayah == selectedAyah;

                 Widget child = Container(
                    decoration: isSelected ? BoxDecoration(
                      color: AppColors.golden.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                        color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      ),
                    ),
                 );
                 
                  // Intearaction
                  if (glyph.surah != null && glyph.ayah != null) {
                     return GestureDetector(
                       onTap: () => onAyahSelected?.call(glyph.surah!, glyph.ayah!),
                       onLongPress: () => onAyahLongPress?.call(glyph.surah!, glyph.ayah!), // Added
                       child: child,
                     );
                  }
                 return child;
              }).toList(),
            ),
          ),
        ),
      );
    }
    
    // Original Rendering for QCF Fonts ...
    return Directionality(
      textDirection: TextDirection.rtl,
      // Reverted to 1000 as per user request (v1.14 state)
      child: SizedBox(
        width: 1000, 
        child: FittedBox(
          fit: BoxFit.scaleDown, // Safeguard against overflow with larger fonts
          child: SizedBox(
            width: 1000, 
            child: Row(
              mainAxisAlignment: _getLineAlignment(line),
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: line.glyphs.map((glyph) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            // تخطي علامات التوقف والسجدة (مدمجة في الخط بالفعل)
            // Type 3 = Pause marks (علامات الوقف)
            // Type 4 = Sajdah marks (علامات السجدة)
            if (glyph.isPause || glyph.isSajdah) {
              return const SizedBox.shrink(); // لا نعرضها منفصلة
            }
            
            // استخدام الأكواد الأصلية من البيانات
            String code = glyph.code;
            
            // البسملة (Type 8): نعرضها كـ 4 كلمات منفصلة
            if (glyph.isBasmala) {
               // حالة خاصة لسورة التوبة (لا بسملة فيها)
              if (glyph.surah == 9) {
                return const SizedBox.shrink();
              }
              // سورة الفاتحة (1) - غالباً لا توجد بسملة منفصلة لأنها آية 1
              if (glyph.surah == 1) {
                 // إذا وجدت، لا بأس بعرضها
              }
              
               // بسم الله الرحمن الرحيم
               // اللون أسود في الوضع الفاتح
               final basmalaColor = isDark ? Colors.white : Colors.black;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\uFAD5', style: TextStyle(fontFamily: 'QCF4_BSML', fontSize: 56.0, color: basmalaColor)), // بسم
                  const SizedBox(width: 4),
                  Text('\uFAD6', style: TextStyle(fontFamily: 'QCF4_BSML', fontSize: 56.0, color: basmalaColor)), // الله
                  const SizedBox(width: 4),
                  Text('\uFAD7', style: TextStyle(fontFamily: 'QCF4_BSML', fontSize: 56.0, color: basmalaColor)), // الرحمن
                  const SizedBox(width: 4),
                  Text('\uFAD8', style: TextStyle(fontFamily: 'QCF4_BSML', fontSize: 56.0, color: basmalaColor)), // الرحيم
                ],
              );
            }
            // اسم السورة (Type 6): نعرض الكود الأصلي (\uf1xx)
            else if (glyph.isSurahName) {
              // الكود موجود أصلاً في البيانات (\uf100 - \uf171)
              // لا نحتاج لتوليده!
              // سيتم عرضه باستخدام Text widget أدناه
            }
            
            // Check selection
            final bool isSelected = selectedSurah != null && 
                                   selectedAyah != null &&
                                   glyph.surah == selectedSurah && 
                                   glyph.ayah == selectedAyah;
            
            Widget child = Container(
              decoration: isSelected ? BoxDecoration(
                color: AppColors.golden.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ) : null,
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: _getFontFamily(glyph),
                  fontSize: _getGlyphSize(glyph),
                  color: _getGlyphColor(glyph, context),
                  height: 1.0, 
                  letterSpacing: 0,
                ),
                textDirection: TextDirection.rtl,
              ),
            );
            
            // Wrap in interaction if it's a verse part
            if ((glyph.isWord || glyph.isAyahEnd) && glyph.surah != null && glyph.ayah != null) {
              return GestureDetector(
                onTap: () => onAyahSelected?.call(glyph.surah!, glyph.ayah!),
                onLongPress: () => onAyahLongPress?.call(glyph.surah!, glyph.ayah!), // Added
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: child,
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: child,
            );
          }).toList(),
        ),
      ),
        ),
      ),
    );
  }

  /// اختيار عائلة الخط حسب نوع العنصر
  String _getFontFamily(Glyph glyph) {
    if (glyph.isSurahName || glyph.isBasmala) {
      return 'QCF4_BSML';
    }
    
    if (isParentFontLoaded) {
      return 'QCF4_${pageNumber.toString().padLeft(3, '0')}';
    }
    
    // Fallback
    if (pageNumber <= 200) return 'QCF_P001';
    if (pageNumber <= 400) return 'QCF_P002';
    return 'QCF_P003';
  }
  
   double _getGlyphSize(Glyph glyph) {
     if (glyph.isBasmala || glyph.isSurahName) {
       return 56.0; // Standardized to match text
     } else if (glyph.isAyahEnd) {
       return 50.0; // Increased
     } else if (glyph.isSajdah) {
       return 48.0; // Increased
     }
     return 56.0; // Increased from 44.0 to 56.0 for better visibility
   }
  
  Color _getGlyphColor(Glyph glyph, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  // اسم السورة: أحمر (Primary)
  if (glyph.isSurahName) {
    return AppColors.primary;
  }
  // البسملة: أسود في الوضع الفاتح
  // ملاحظة: اللون هنا يستخدم فقط إذا لم يتم استخدام الـ Row المخصص أعلاه
  // ولكن بما أننا نستخدم Row مخصص للبسملة، هذا الكود لن يؤثر عليها غالباً
  else if (glyph.isBasmala) {
     return isDark ? Colors.white : Colors.black;
  }
  // أرقام الآيات: أحمر وذهبي
  else if (glyph.isAyahEnd) {
    return isDark ? AppColors.golden : AppColors.primary;
  } 
  // تم حذف كود isPause
  else if (glyph.isSajdah) {
    return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
  }
  
  // اللون الأساسي: أسود في الوضع الفاتح
  return isDark ? Colors.white : Colors.black;
}

  MainAxisAlignment _getLineAlignment(PageLine line) {
    // Special lines (Headers) are always centered
    if (line.glyphs.any((g) => g.isBasmala || g.isSurahName)) {
      return MainAxisAlignment.center;
    }

    // Count meaningful words
    final wordCount = line.glyphs.where((g) => g.isWord).length;

    // Use MainAxisAlignment.spaceBetween for almost all lines to justify them to edges.
    // Only use Center if the line is EXTREMELY short (e.g. end of Surah with 1-2 words).
    // The previous threshold of 15/35 was way too high, causing all lines to center and create margins.
    if (wordCount < 6) { 
      return MainAxisAlignment.center;
    }

    return MainAxisAlignment.spaceBetween;
  }
}
