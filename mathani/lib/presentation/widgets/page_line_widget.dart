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
  final String? mushafId; // Added
  final bool? isCentered; // Official alignment from QUL database (null = use fallback heuristic)
  
  const PageLineWidget({
    Key? key,
    required this.line,
    required this.pageNumber,
    required this.isParentFontLoaded,
    this.onAyahSelected,
    this.onAyahLongPress,
    this.selectedSurah,
    this.selectedAyah,
    this.isDigital = false,
    this.digitalWords,
    this.mushafId,
    this.isCentered,
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
            
            if ((glyph.isPause || glyph.isSajdah) && mushafId != 'madani_old_v1') {
              return const SizedBox.shrink();
            }
            
            // استخدام الأكواد الأصلية من البيانات
            String code = glyph.code;
            
            // البسملة (Type 8): نعرضها كـ 4 كلمات منفصلة
            // ملاحظة: في QPC V1، البسملة جزء من نص الصفحة وتأتي كـ Glyph بكود PUA
              // Basmala (Type 8): نعرضها كـ 4 كلمات منفصلة أو باستخدام خط QCF4 مباشرة
             if (glyph.isBasmala) {
               // إذا كنا في V1 الآن نستخدم نفس منطق QCF4 (خط QCF4_BSML)
               // لأننا غيرنا الكود في LayoutService ليكون 'BSML' وهو مجرد placeholder
               // هنا سنستخدم التصيير القياسي للبسملة
               
                   // بسم الله الرحمن الرحيم
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
             // اسم السورة (Type 6): نعرض الكود الأصلي (من QCF4)
             else if (glyph.isSurahName) {
               // الكود الآن يأتي من LayoutService بصيغة QCF4 Standard
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

  String _getFontFamily(Glyph glyph) {
    if (mushafId == 'madani_old_v1') {
       // Headers use QCF4_BSML (User Request)
       if (glyph.isSurahName || glyph.isBasmala || glyph.type == 6 || glyph.type == 8) {
         return 'QCF4_BSML';
       }
       
       // Ayah End (Type 2) typically uses Page Font which contains the number glyph
       // Fallback to Amiri only if explicitly standard '06DD'
       if (glyph.isAyahEnd && glyph.code == '\u06DD') {
         return 'Amiri';
       }
       
       // Words and Page-specific Glyphs use the Page Font
       if (isParentFontLoaded) {
         return 'p$pageNumber-v1';
       }
       return 'Amiri';
    }

    // ... existing logic for QCF4 ...
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
  
  // ... existing methods ...

  MainAxisAlignment _getLineAlignment(PageLine line) {
    // If we have official is_centered data from QUL, use it directly
    if (isCentered != null) {
      return isCentered! ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween;
    }

    // === Fallback heuristic (V1 or if alignment data not available) ===
    
    // Pure Header lines are centered
    if (line.glyphs.any((g) => g.isBasmala || g.isSurahName)) {
      return MainAxisAlignment.center;
    }

    final wordCount = line.glyphs.where((g) => g.isWord).length;

    if (pageNumber <= 2) {
      if (wordCount < 8) return MainAxisAlignment.center;
    }

    // Very short lines always centered
    if (wordCount < 4) {
      return MainAxisAlignment.center;
    }

    return MainAxisAlignment.spaceBetween;
  }
  
   double _getGlyphSize(Glyph glyph) {
     if (mushafId == 'madani_old_v1') {
        if (glyph.isSurahName || glyph.isBasmala) return 56.0;
        if (glyph.isAyahEnd) return 54.0; // Slightly smaller than words
        return 58.0; // Balanced size: less FittedBox compression, consistent stroke
     }
     
     if (glyph.isBasmala || glyph.isSurahName) {
       return 56.0; 
     } else if (glyph.isAyahEnd) {
       return 50.0; 
     } else if (glyph.isSajdah) {
       return 48.0; 
     }
     return 56.0; 
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


}
