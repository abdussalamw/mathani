import 'package:flutter/material.dart';
import '../../data/models/page_glyph.dart';
import '../../core/constants/app_colors.dart';

/// Widget لعرض سطر واحد من صفحة المصحف
class PageLineWidget extends StatelessWidget {
  final PageLine line;
  final int pageNumber;
  final bool isParentFontLoaded;
  final Function(int surah, int ayah)? onAyahSelected;
  final int? selectedSurah;
  final int? selectedAyah;
  
  const PageLineWidget({
    Key? key,
    required this.line,
    required this.pageNumber,
    required this.isParentFontLoaded,
    this.onAyahSelected,
    this.selectedSurah,
    this.selectedAyah,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: _getLineAlignment(line),
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: line.glyphs.map((glyph) {
            // تصحيح البسملة إذا كانت فارغة
            String code = glyph.code;
            if (glyph.isBasmala && (code.isEmpty || code.length > 2)) { 
               code = '\uFDFD'; // ﷽
            }
            
            // Check selection
            final bool isSelected = selectedSurah != null && 
                                   selectedAyah != null &&
                                   glyph.surah == selectedSurah && 
                                   glyph.ayah == selectedAyah; // Fixed logic to require both
            
            Widget child = Text(
              code,
              style: TextStyle(
                fontFamily: _getFontFamily(glyph),
                fontSize: _getGlyphSize(glyph),
                color: _getGlyphColor(glyph, context),
                height: 1.0, 
                letterSpacing: 0,
                backgroundColor: isSelected ? AppColors.golden.withValues(alpha: 0.3) : null,
              ),
              textDirection: TextDirection.rtl,
            );
            
            // Wrap in interaction if it's a verse part
            if ((glyph.isWord || glyph.isAyahEnd) && glyph.surah != null && glyph.ayah != null) {
              return GestureDetector(
                onTap: () => onAyahSelected?.call(glyph.surah!, glyph.ayah!),
                behavior: HitTestBehavior.translucent, // Catch taps even on transparent areas
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0), // Reduced to 1.0 to minimize height and allow wider fit
                  child: child,
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0), // Reduced to 1.0
              child: child,
            );
          }).toList(),
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
      return 42.0; // Increased from 28.0
    } else if (glyph.isAyahEnd) {
      return 32.0; // Increased from 22.0
    } else if (glyph.isPause || glyph.isSajdah) {
      return 30.0; // Increased from 20.0
    }
    return 36.0; // Increased from 24.0
  }
  
  Color _getGlyphColor(Glyph glyph, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (glyph.isBasmala || glyph.isSurahName) {
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (glyph.isAyahEnd) {
      return isDark ? Colors.amber.shade300 : Colors.amber.shade700;
    } else if (glyph.isPause) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else if (glyph.isSajdah) {
      return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
    }
    
    return isDark ? Colors.white : const Color(0xFF2C1810);
  }

  MainAxisAlignment _getLineAlignment(PageLine line) {
    final isSpecialLine = line.glyphs.any((g) => g.isBasmala || g.isSurahName);
    if (isSpecialLine) {
      return MainAxisAlignment.center;
    }

    final endsWithAyah = line.glyphs.isNotEmpty && (line.glyphs.last.isAyahEnd || line.glyphs.last.code == '\u06DD');
    final textGlyphsCount = line.glyphs.where((g) => !g.isAyahEnd && !g.isPause).length;
    
    // Short lines (like in Page 604 or end of Surahs) look better Center-aligned
    if (endsWithAyah) {
      if (textGlyphsCount < 35) {
        return MainAxisAlignment.center; // Changed from start to center
      }
    }
    
    // Very short lines in general
    if (textGlyphsCount < 15) {
      return MainAxisAlignment.center;
    }

    return MainAxisAlignment.spaceBetween;
  }
}
