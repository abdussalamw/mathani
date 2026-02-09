import 'package:flutter/material.dart';
import '../../data/models/page_glyph.dart';
import '../../data/models/ayah.dart';
import '../../core/constants/app_colors.dart';
import 'page_line_widget.dart';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/gestures.dart';

import '../../data/services/qcf4_font_downloader.dart';
import '../../presentation/providers/quran_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/bookmark_provider.dart';
import '../../core/constants/responsive_constants.dart';
import 'package:provider/provider.dart';

/// Widget لعرض صفحة كاملة من المصحف
class MushafPageWidget extends StatefulWidget {
  final PageGlyph page;
  final int? selectedSurah;
  final int? selectedAyah;
  final Function(int surah, int ayah)? onAyahSelected;
  final bool showInfo;
  final bool isDigital;
  
  const MushafPageWidget({
    Key? key,
    required this.page,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahSelected,
    this.showInfo = true,
    this.isDigital = false,
  }) : super(key: key);

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  bool _isFontLoaded = false;
  List<Ayah>? _digitalAyahs;
  bool _isLoadingDigital = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.page != widget.page.page || oldWidget.isDigital != widget.isDigital) {
      _loadData();
    }
  }

  Map<int, List<String>> _lineWordsMap = {};

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoadingDigital = true);
    
    try {
      // Always fetch ayahs for the page metadata (Surah Name, Bookmark location)
      final ayahs = await context.read<QuranProvider>().getAyahsForPage(widget.page.page);
      
      if (mounted) {
        setState(() {
          _digitalAyahs = ayahs;
          if (widget.isDigital) {
            _mapWords();
            _isFontLoaded = true; // Digital text doesn't need woff2 loading
          }
          _isLoadingDigital = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading page metadata: $e');
      if (mounted) setState(() => _isLoadingDigital = false);
    }
    
    // QCF Font Loading
    if (!widget.isDigital) {
      final loaded = await QCF4FontDownloader.loadPageFont(widget.page.page);
      // Removed loadBasmalaFont() since it's now a bundled asset in pubspec
      if (mounted) {
        setState(() {
          _isFontLoaded = loaded;
        });
      }
    }
  }

  void _mapWords() {
    if (_digitalAyahs == null) return;
    _lineWordsMap.clear();

    final Queue<String> wordQueue = Queue();
    // Ensure accurate order. Assuming _digitalAyahs is sorted by Surah/Ayah.
    
    for (var ayah in _digitalAyahs!) {
       // Filter empty splits
       final words = ayah.text.split(' ').where((w) => w.isNotEmpty).toList();
       wordQueue.addAll(words);
    }

    // Distribute
    for (var line in widget.page.lines) {
       List<String> currentLineWords = [];
       for (var glyph in line.glyphs) {
          if (glyph.isWord) {
             if (wordQueue.isNotEmpty) {
                currentLineWords.add(wordQueue.removeFirst());
             } else {
                currentLineWords.add('(?)'); // Hint for mismatch
             }
          }
       }
       _lineWordsMap[line.line] = currentLineWords;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // حساب الأبعاد الديناميكية باستخدام ResponsiveConstants
    final topBarHeight = ResponsiveConstants.getTopBarHeight(context);
    final bottomBarHeight = ResponsiveConstants.getBottomBarHeight(context);
    final contentWidth = ResponsiveConstants.getContentWidth(context);
    
    // التحقق من صلاحية الشاشة (للتطوير فقط)
    final validation = ResponsiveConstants.validateScreen(context);
    if (!validation.isValid && validation.getWarningMessage() != null) {
      debugPrint('⚠️ Screen Warning: ${validation.getWarningMessage()}');
      debugPrint('   Line Height: ${validation.lineHeight.toStringAsFixed(1)}px');
      debugPrint('   Content Width: ${validation.contentWidth.toStringAsFixed(1)}px');
      debugPrint('   Ideal Width: ${validation.idealWidth.toStringAsFixed(1)}px');
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2C2416) 
            : const Color(0xFFFFFBF0),
        image: isDark ? null : const DecorationImage(
          image: AssetImage('assets/images/mushaf_texture.png'),
          fit: BoxFit.cover,
          opacity: 0.15, // Very subtle
        ),
      ),
      child: Column(
        children: [
          // 1. الشريط العلوي (ارتفاع ديناميكي)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.showInfo ? 1.0 : 0.0,
            child: SizedBox(
              height: topBarHeight,
              child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // --- 1. Right Side: Juz Name ---
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<QuranProvider>(
                          builder: (context, quran, child) {
                             int? juzNumber;
                             if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                                 juzNumber = _digitalAyahs!.first.juz; 
                             }
                             if (juzNumber == null) {
                                juzNumber = ((widget.page.page - 2) / 20).floor() + 1;
                                if (juzNumber < 1) juzNumber = 1;
                                if (juzNumber > 30) juzNumber = 30;
                             }

                             // QCF4_BSML Juz Range: 0xF1D8 (Juz 1) -> 0xF1F5 (Juz 30)
                             final int juzCodePoint = 0xF1D8 + (juzNumber - 1);
                             final String juzGlyph = String.fromCharCode(juzCodePoint);
                                  
                             return Text(
                                juzGlyph,
                                style: const TextStyle(
                                  fontFamily: 'QCF4_BSML', 
                                  fontSize: 18, 
                                  color: AppColors.primary,
                                  height: 1.0, 
                                ),
                              );
                          },
                        ),
                      ),
                    ),

                    // --- 2. Center: Surah Name ---
                    Consumer<QuranProvider>(
                      builder: (context, quran, child) {
                        int? surahNumber;
                        if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                           surahNumber = _digitalAyahs!.first.surahNumber;
                        } else {
                          for (var line in widget.page.lines) {
                            for (var glyph in line.glyphs) {
                              if (glyph.surah != null) {
                                surahNumber = glyph.surah;
                                break;
                              }
                            }
                            if (surahNumber != null) break;
                          }
                        }

                        if (surahNumber != null) {
                           final int surahCodePoint = 0xF100 + (surahNumber - 1);
                           final String surahGlyph = String.fromCharCode(surahCodePoint);
                           
                           return Text(
                              surahGlyph,
                              style: const TextStyle(
                                fontFamily: 'QCF4_BSML', 
                                fontSize: 12, 
                                color: AppColors.primary,
                                height: 1.0, 
                              ),
                            );
                        }
                        return const SizedBox.shrink(); 
                      },
                    ),

                    // --- 3. Left Side: Icons + Page Number ---
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             // Theme Toggle
                             Consumer<SettingsProvider>(
                               builder: (context, settings, child) {
                                 return InkWell(
                                   onTap: () => settings.toggleDarkMode(),
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(horizontal: 4), 
                                     child: Icon(
                                       settings.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                                       size: 16,
                                       color: AppColors.primary,
                                     ),
                                   ),
                                 );
                               },
                             ),

                             const SizedBox(width: 8),

                             // Bookmark Toggle
                             Consumer<BookmarkProvider>(
                               builder: (context, bookmarks, child) {
                                 bool isBookmarked = false;
                                 int? targetSurah, targetAyah;
                                 
                                 if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                                    targetSurah = _digitalAyahs!.first.surahNumber;
                                    targetAyah = _digitalAyahs!.first.ayahNumber;
                                 } else {
                                    if (widget.page.lines.isNotEmpty) {
                                       for (var g in widget.page.lines.first.glyphs) {
                                          if (g.surah != null && g.ayah != null) {
                                             targetSurah = g.surah;
                                             targetAyah = g.ayah;
                                             break;
                                          }
                                       }
                                    }
                                 }

                                 if (targetSurah != null && targetAyah != null) {
                                    isBookmarked = bookmarks.isBookmarked(targetSurah, targetAyah);
                                 }

                                 return InkWell(
                                   onTap: () {
                                      if (targetSurah != null && targetAyah != null) {
                                         if (isBookmarked) {
                                            bookmarks.removeBookmark(targetSurah!, targetAyah!);
                                         } else {
                                            bookmarks.addBookmark(targetSurah!, targetAyah!, note: 'صفحة ${widget.page.page}');
                                         }
                                      }
                                   },
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(horizontal: 4),
                                     child: Icon(
                                       isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                       size: 16,
                                       color: AppColors.primary,
                                     ),
                                   ),
                                 );
                               },
                             ),
                             
                             const SizedBox(width: 8),

                             // Page Number
                             Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _convertToArabicNumbers(widget.page.page),
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal', 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          
          // 2. المحتوى (15 سطر - عرض محدود ديناميكياً)
          Expanded(
            child: Center( // توسيط المحتوى أفقياً
              child: SizedBox(
                width: contentWidth, // عرض ديناميكي بناءً على نسبة الارتفاع/العرض
                child: widget.isDigital && _isLoadingDigital
                    ? const Center(child: CircularProgressIndicator()) 
                    : (!_isFontLoaded 
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                            // Digital Mode: Full Screen Flex Layout
                            if (widget.isDigital) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                // Fixed margins to avoid jump when bars toggle
                                // Top: 60 (Safe Area + Status Bar)
                                // Bottom: 140 (Navigation Bar Clearance)
                                padding: const EdgeInsets.only(top: 60, bottom: 140, left: 24, right: 24), 
                                child: Column(
                                  // Center content vertically if lines are few (e.g. Page 1 & 2)
                                  // Distribute evenly (spaceBetween) if it's a full page (15 lines).
                                  mainAxisAlignment: widget.page.lines.length < 13 
                                      ? MainAxisAlignment.center 
                                      : MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: widget.page.lines.map((line) {
                                    return Container(
                                      // Add minimal vertical padding for pages with few lines to separate them
                                      padding: widget.page.lines.length < 13 
                                          ? const EdgeInsets.symmetric(vertical: 8.0) 
                                          : EdgeInsets.zero,
                                      child: PageLineWidget(
                                        line: line,
                                        pageNumber: widget.page.page,
                                        isParentFontLoaded: _isFontLoaded,
                                        selectedSurah: widget.selectedSurah,
                                        selectedAyah: widget.selectedAyah,
                                        onAyahSelected: widget.onAyahSelected,
                                        isDigital: widget.isDigital,
                                        digitalWords: _lineWordsMap[line.line],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                            // QCF Mode: Force Expand Horizontally
                            // We use a FittedBox on the COLUMN itself with fitWidth.
                            // This takes the 'ideal' layout (width 1000) and STRETCHES it to touch the screen edges.
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              // Fixed margins to avoid jump when bars toggle
                              // Top: 60, Bottom: 180 (Increased to lift last line clear of bottom bar)
                              padding: const EdgeInsets.only(top: 60, bottom: 180, left: 16, right: 16),
                              child: FittedBox(
                                fit: BoxFit.fitWidth, 
                                child: SizedBox(
                                  // Reverted reference width from 1200 back to 1000 (v1.14 state)
                                  width: 1000,
                                  height: 1800, 
                                  child: Column(
                                    // Reverted logic to only center short pages < 13 lines (removed page <= 2 specific check)
                                    mainAxisAlignment: widget.page.lines.length < 13 
                                        ? MainAxisAlignment.center 
                                        : MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: widget.page.lines.map((line) {
                                      return Container(
                                        padding: widget.page.lines.length < 13 
                                            ? const EdgeInsets.symmetric(vertical: 12.0) 
                                            : EdgeInsets.zero,
                                        child: PageLineWidget(
                                          line: line,
                                          pageNumber: widget.page.page,
                                          isParentFontLoaded: _isFontLoaded,
                                          selectedSurah: widget.selectedSurah,
                                          selectedAyah: widget.selectedAyah,
                                          onAyahSelected: widget.onAyahSelected,
                                          isDigital: widget.isDigital,
                                          digitalWords: widget.isDigital ? _lineWordsMap[line.line] : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSurahHeader(int surahNum, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.golden.withOpacity(0.1),
        border: Border.all(color: AppColors.golden),
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Center(
        child: Text(
           'سورة رقم $surahNum', // Ideally fetch name
           style: TextStyle(
             fontFamily: 'Tajawal',
             fontWeight: FontWeight.bold,
             fontSize: 14,
             color: AppColors.golden,
           ),
        ),
      ),
    );
  }
  
  Widget _buildBasmala(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: TextStyle(
          fontFamily: 'KFGQPC_HAFS', // خط القرآن الكريم
          fontSize: 28,
          color: isDark ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _convertToArabicNumbers(int number) {
    if (number == 0) return '٠';
    // Simplified check based on UI requirements
    // For now, let's just implement the conversion logic
    // The user said: "Arabic in Arabic mode, English in English mode"
    // I'll check directionality or locale
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    if (!isArabic) return number.toString();

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
        result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
