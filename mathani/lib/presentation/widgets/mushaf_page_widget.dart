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
      await QCF4FontDownloader.loadBasmalaFont();
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
          // شريط المعلومات العلوي
          // We keep this in the tree but hide opacity to prevent layout jumps
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.showInfo ? 1.0 : 0.0,
            child: Padding(
              // Increased top padding to push header BELOW the status bar, not underneath/over it.
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Right Side (RTL Start): Surah Name
                  Consumer<QuranProvider>(
                    builder: (context, quran, child) {
                      String surahNameText = '';
                      String surahNameGlyph = '';
                      
                      // 1. Try to find the exact surah name glyph on this page
                      for (var line in widget.page.lines) {
                        for (var glyph in line.glyphs) {
                          if (glyph.isSurahName && glyph.code.isNotEmpty) {
                            surahNameGlyph = glyph.code;
                            break;
                          }
                        }
                        if (surahNameGlyph.isNotEmpty) break;
                      }

                      // 2. Fetch Surah Number for metadata/text fallback
                      int? surahNumber;
                      if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                         surahNumber = _digitalAyahs!.first.surahNumber;
                      } else {
                         // Glyph search
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

                      // 3. Prepare text fallback name
                      if (surahNumber != null && quran.surahs.isNotEmpty) {
                        try {
                          final surah = quran.surahs.firstWhere((s) => s.number == surahNumber);
                          surahNameText = surah.nameArabic;
                        } catch (_) {}
                      }

                      // IF we found a glyph, show it calligraphically!
                      if (surahNameGlyph.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0), // Shift down slightly for alignment
                          child: Text(
                            surahNameGlyph,
                            style: const TextStyle(
                              fontFamily: 'QCF4_BSML', 
                              fontSize: 32, // Large enough for calligraphy
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      // Fallback to text
                      return Text(
                        surahNameText.isNotEmpty ? 'سورة $surahNameText' : 'تحميل...',
                        style: const TextStyle(
                          fontFamily: 'Tajawal', 
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  
                  // Left Side (RTL End): Icons + Page Number at the end
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Theme Toggle
                       Consumer<SettingsProvider>(
                         builder: (context, settings, child) {
                           return InkWell(
                             onTap: () => settings.toggleDarkMode(),
                             child: Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 6), // Increased spacing
                               child: Icon(
                                 settings.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                                 size: 16,
                                 color: AppColors.primary,
                               ),
                             ),
                           );
                         },
                       ),
                       
                       const SizedBox(width: 12), // Added more spacing

                       // Bookmark Toggle
                       Consumer<BookmarkProvider>(
                         builder: (context, bookmarks, child) {
                           // Use _digitalAyahs as reliable source for location
                           int? surah, ayah;
                           if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                              surah = _digitalAyahs!.first.surahNumber;
                              ayah = _digitalAyahs!.first.ayahNumber;
                           } else {
                              // Glyph fallback
                              for (var line in widget.page.lines) {
                                for (var glyph in line.glyphs) {
                                  if (glyph.surah != null && glyph.ayah != null) {
                                    surah = glyph.surah;
                                    ayah = glyph.ayah;
                                    break;
                                  }
                                }
                                if (surah != null) break;
                              }
                           }
                           
                           final isBookmarked = (surah != null && ayah != null) 
                               ? bookmarks.isBookmarked(surah, ayah) 
                               : false;

                           return InkWell(
                             onTap: () {
                               if (surah != null && ayah != null) {
                                 if (isBookmarked) {
                                   bookmarks.removeBookmark(surah, ayah);
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('تم إزالة العلامة المرجعية', style: TextStyle(fontFamily: 'Tajawal')), duration: Duration(seconds: 1)),
                                   );
                                 } else {
                                   bookmarks.addBookmark(surah, ayah, note: 'صفحة ${widget.page.page}');
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('تم إضافة علامة مرجعية', style: TextStyle(fontFamily: 'Tajawal')), duration: Duration(seconds: 1)),
                                   );
                                 }
                               } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('لم يتم تحديد موقع الصفحة بعد', style: TextStyle(fontFamily: 'Tajawal')), duration: Duration(seconds: 1)),
                                  );
                               }
                             },
                             child: Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 6), // Increased spacing
                               child: Icon(
                                 isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                 size: 16,
                                 color: AppColors.primary,
                               ),
                             ),
                           );
                         },
                       ),

                       const SizedBox(width: 12), // Spacing between icon and text

                       Text(
                        'صفحة رقم ${widget.page.page}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // الأسطر / النص
          Expanded(
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
                        ))),
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
          fontFamily: 'Amiri', // Or specialized Basmala font
          fontSize: 28,
          color: isDark ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
