import 'package:material_ui/material_ui.dart';

import 'ayah_press_target.dart';

import '../../data/models/page_glyph.dart';
import '../../core/constants/app_colors.dart';

import '../../data/models/recitation_result.dart';

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
  final Map<Glyph, String> wordKeys;
  final Map<String, WordVerdict> wordVerdicts;
  final Set<String>? revealedWordKeys;

  const PageLineWidget({
    super.key,
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
    this.wordKeys = const {},
    this.wordVerdicts = const {},
    this.revealedWordKeys,
  });

  bool _isHiddenWord(Glyph glyph) =>
      glyph.isWord && revealedWordKeys?.contains(wordKeys[glyph]) == false;

  @override
  Widget build(BuildContext context) {
    // If Digital Mode with available words mapping, we behave like the standard layout but with digital text.
    if (isDigital) {
      if (digitalWords == null) {
        return Container(); // Fallback if data not ready
      }

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

                final isSelected =
                    selectedSurah != null &&
                    selectedAyah != null &&
                    glyph.surah == selectedSurah &&
                    glyph.ayah == selectedAyah;

                // تلوين الكلمات لحظياً أثناء التسميع
                final liveVerdict = wordVerdicts[wordKeys[glyph]];

                BoxDecoration decoration = const BoxDecoration();
                Color? customColor;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                if (liveVerdict != null) {
                  if (liveVerdict == WordVerdict.correct) {
                    decoration = BoxDecoration(
                      color: Colors.green.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.green.shade300
                        : Colors.green.shade700;
                  } else if (liveVerdict == WordVerdict.incorrect) {
                    decoration = BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.red.shade300
                        : Colors.red.shade700;
                  } else if (liveVerdict == WordVerdict.acceptable) {
                    decoration = BoxDecoration(
                      color: Colors.orange.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade700;
                  }
                } else if (isSelected) {
                  decoration = BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  );
                }

                Widget child = AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  decoration: decoration,
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      color:
                          customColor ??
                          color ??
                          (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    ),
                    child: Text(text),
                  ),
                );

                if (_isHiddenWord(glyph)) {
                  return Opacity(opacity: 0, child: child);
                }

                // Intearaction
                if (revealedWordKeys == null &&
                    glyph.surah != null &&
                    glyph.ayah != null) {
                  return AyahPressTarget(
                    onSelected:
                        onAyahLongPress == null && onAyahSelected == null
                        ? null
                        : () => (onAyahLongPress ?? onAyahSelected)?.call(
                            glyph.surah!,
                            glyph.ayah!,
                          ),
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
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown, // Safeguard against overflow with larger fonts
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: Row(
              mainAxisAlignment: _getLineAlignment(line),
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: line.glyphs.map((glyph) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                if ((glyph.isPause || glyph.isSajdah) &&
                    mushafId != 'madani_old_v1') {
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
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: TextStyle(
                      fontFamily: 'QCF4_BSML',
                      fontSize: 56.0,
                      color: basmalaColor,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('\uFAD5'), // بسم
                        SizedBox(width: 4),
                        Text('\uFAD6'), // الله
                        SizedBox(width: 4),
                        Text('\uFAD7'), // الرحمن
                        SizedBox(width: 4),
                        Text('\uFAD8'), // الرحيم
                      ],
                    ),
                  );
                }
                // اسم السورة (Type 6): نعرض الكود الأصلي (من QCF4)
                else if (glyph.isSurahName) {
                  // الكود الآن يأتي من LayoutService بصيغة QCF4 Standard
                }

                // Check selection
                final bool isSelected =
                    selectedSurah != null &&
                    selectedAyah != null &&
                    glyph.surah == selectedSurah &&
                    glyph.ayah == selectedAyah;

                // تلوين الكلمات لحظياً أثناء التسميع
                final liveVerdict = wordVerdicts[wordKeys[glyph]];

                BoxDecoration decoration = const BoxDecoration();
                Color? customColor;

                if (liveVerdict != null) {
                  if (liveVerdict == WordVerdict.correct) {
                    decoration = BoxDecoration(
                      color: Colors.green.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.green.shade300
                        : Colors.green.shade700;
                  } else if (liveVerdict == WordVerdict.incorrect) {
                    decoration = BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.red.shade300
                        : Colors.red.shade700;
                  } else if (liveVerdict == WordVerdict.acceptable) {
                    decoration = BoxDecoration(
                      color: Colors.orange.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    );
                    customColor = isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade700;
                  }
                } else if (isSelected) {
                  decoration = BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  );
                }

                Widget child = AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  decoration: decoration,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: TextStyle(
                      fontFamily: _getFontFamily(glyph),
                      fontSize: _getGlyphSize(glyph),
                      fontWeight: FontWeight.normal,
                      color: customColor ?? _getGlyphColor(glyph, context),
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                    child: Text(code, textDirection: TextDirection.rtl),
                  ),
                );

                if (_isHiddenWord(glyph)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0),
                    child: Opacity(opacity: 0, child: child),
                  );
                }

                // Wrap in interaction if it's a verse part
                if (revealedWordKeys == null &&
                    (glyph.isWord || glyph.isAyahEnd) &&
                    glyph.surah != null &&
                    glyph.ayah != null) {
                  return AyahPressTarget(
                    onSelected:
                        onAyahLongPress == null && onAyahSelected == null
                        ? null
                        : () => (onAyahLongPress ?? onAyahSelected)?.call(
                            glyph.surah!,
                            glyph.ayah!,
                          ),
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
      if (glyph.isSurahName ||
          glyph.isBasmala ||
          glyph.type == 6 ||
          glyph.type == 8) {
        return 'QCF4_BSML';
      }

      // Ayah End (Type 2) typically uses Page Font which contains the number glyph
      // Fallback to Amiri only if explicitly standard '06DD'
      if (glyph.isAyahEnd && glyph.code == '\u06DD') {
        return 'KFGQPC_HAFS';
      }

      // Words and Page-specific Glyphs use the Page Font
      if (isParentFontLoaded) {
        return 'p$pageNumber-v1';
      }
      return 'KFGQPC_HAFS';
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
      return isCentered!
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween;
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
      if (glyph.isSurahName || glyph.isBasmala) return 72.0;
      if (glyph.isAyahEnd) return 66.0;
      return 72.0;
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
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    // اسم السورة: أحمر (Primary)
    if (glyph.isSurahName) {
      return AppColors.primary;
    }
    // البسملة: أسود في الوضع الفاتح
    else if (glyph.isBasmala) {
      return isDark ? Colors.white : Colors.black;
    }
    // أرقام الآيات: أحمر وذهبي
    else if (glyph.isAyahEnd) {
      return isDark ? AppColors.golden : AppColors.primary;
    } else if (glyph.isSajdah) {
      return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
    }

    // اللون الأساسي
    // V1 على الجوال: رمادي غامق بدل الأسود القاتم لتقليل تأثير العرض
    if (mushafId == 'madani_old_v1' && isMobile && !isDark) {
      return const Color(0xFF2A2A2A); // رمادي غامق جداً بدل الأسود
    }
    return isDark ? Colors.white : Colors.black;
  }
}
