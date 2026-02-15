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
import '../../presentation/providers/ui_provider.dart';
import '../../data/providers/mushaf_navigation_provider.dart';
import '../../core/constants/responsive_constants.dart';
import 'package:provider/provider.dart';

/// Widget لعرض صفحة كاملة من المصحف
class MushafPageWidget extends StatefulWidget {
  final PageGlyph page;
  final int? selectedSurah;
  final int? selectedAyah;
  final Function(int surah, int ayah)? onAyahSelected;
  final Function(int surah, int ayah)? onAyahLongPress; // Added
  final bool showInfo;
  final bool isDigital;
  
  const MushafPageWidget({
    Key? key,
    required this.page,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahSelected,
    this.onAyahLongPress, // Added
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ResponsiveConstants.printLayoutReport(context);
    });
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
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    
    // حساب الأبعاد الديناميكية باستخدام ResponsiveConstants
    final topBarHeight = ResponsiveConstants.getTopBarHeight(context);
    final bottomBarHeight = ResponsiveConstants.getBottomBarHeight(context);
    // التحقق من صلاحية الشاشة (للتطوير فقط)
    final validation = ResponsiveConstants.validateLayout(context);
    if (!validation.isValid && validation.getWarningMessage() != null) {
      debugPrint('⚠️ Screen Warning: ${validation.getWarningMessage()}');
      debugPrint('   Content Height: ${validation.contentHeight.toStringAsFixed(1)}px');
      debugPrint('   Total Height: ${validation.totalHeight.toStringAsFixed(1)}px');
    }
    
    return Container(
      decoration: BoxDecoration(
        color: settings.backgroundColor,
        image: (isDark || settings.backgroundColorMode == 'white') ? null : const DecorationImage(
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
                    // --- 1. Right Side: Juz Name (Clickable) ---
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<MushafNavigationProvider>(
                          builder: (context, navProvider, child) {
                            final pageInfo = navProvider.getPageInfo(widget.page.page);
                            final juzNumber = pageInfo?.juz ?? 1;

                            // QCF4_BSML Juz Range: 0xF1D8 (Juz 1) -> 0xF1F5 (Juz 30)
                            final int juzCodePoint = 0xF1D8 + (juzNumber - 1);
                            final String juzGlyph = String.fromCharCode(juzCodePoint);
                                 
                            return InkWell(
                              onTap: () {
                                // Navigate to Juz index (tab 1 in IndexScreen)
                                final uiProvider = Provider.of<UiProvider>(context, listen: false);
                                uiProvider.setTabIndex(0, indexScreenTab: 1); // Go to IndexScreen, Juz tab
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  juzGlyph,
                                  style: const TextStyle(
                                    fontFamily: 'QCF4_BSML', 
                                    fontSize: 20, 
                                    color: AppColors.primary,
                                    height: 1.0, 
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // --- 2. Center: Surah Name (Clickable) ---
                    Expanded(
                      child: Center(
                        child: Consumer<MushafNavigationProvider>(
                          builder: (context, navProvider, child) {
                            final pageInfo = navProvider.getPageInfo(widget.page.page);
                            final surahs = pageInfo?.surahs ?? [];
                            final surahNumber = surahs.isNotEmpty ? surahs.first : null;

                            if (surahNumber != null) {
                              final int surahCodePoint = 0xF100 + (surahNumber - 1);
                              final String surahGlyph = String.fromCharCode(surahCodePoint);
                              
                              return InkWell(
                                onTap: () {
                                  // Navigate to Surah index (tab 0 in IndexScreen)
                                  final uiProvider = Provider.of<UiProvider>(context, listen: false);
                                  uiProvider.setTabIndex(0); // Go to IndexScreen (Surah tab is default)
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    surahGlyph,
                                    style: const TextStyle(
                                      fontFamily: 'QCF4_BSML', 
                                      fontSize: 11, 
                                      color: AppColors.primary,
                                      height: 1.0, 
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink(); 
                          },
                        ),
                      ),
                    ),

                    // --- 3. Left Side: Icons + Page Number ---
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Consumer<SettingsProvider>(
                               builder: (context, settings, child) {
                                 return InkWell(
                                   onTap: () => settings.toggleDarkMode(),
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(horizontal: 4), 
                                     child: Icon(
                                       settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                       size: 22,
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

                             // Page Number (Clickable, no background)
                             InkWell(
                               onTap: () {
                                 // Show page jump dialog
                                 _showPageJumpDialog(context);
                               },
                               child: Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                width: ResponsiveConstants.getContentHeight(context) * 0.8, // عرض ديناميكي بناءً على نسبة الارتفاع/العرض
                child: widget.isDigital && _isLoadingDigital
                    ? const Center(child: CircularProgressIndicator()) 
                    : (!_isFontLoaded 
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                            // Digital Mode: Full Screen Flex Layout
                            // ✅ الحل الصحيح
                            // getTopBarHeight يحتوي بالفعل على viewPadding.top (status bar)
                            // لذلك نستخدم فقط safetyMarginTop كمسافة إضافية صغيرة
                            final topPadding = ResponsiveConstants.safetyMarginTop;
                            final bottomPadding = ResponsiveConstants.getBottomBarHeight(context) 
                                                + ResponsiveConstants.safetyMarginBottom;

                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: EdgeInsets.only(
                                 top: topPadding, 
                                 bottom: bottomPadding, 
                                 left: 16, 
                                 right: 16
                              ),
                              child: ResponsiveConstants.getDeviceType(context) == DeviceType.mobile
                                  ? _buildMobileLayout()
                                  : _buildTabletLayout(),
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
  
  /// تخطيط الجوال: توسع كامل بين الشريطين
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: widget.page.lines.length < 13 
          ? MainAxisAlignment.center 
          : MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.page.lines.map((line) {
        return Expanded(
          child: Center(
            child: PageLineWidget(
              line: line,
              pageNumber: widget.page.page,
              isParentFontLoaded: _isFontLoaded,
              selectedSurah: widget.selectedSurah,
              selectedAyah: widget.selectedAyah,
              onAyahSelected: widget.onAyahSelected,
              onAyahLongPress: widget.onAyahLongPress,
              isDigital: widget.isDigital,
              digitalWords: widget.isDigital ? _lineWordsMap[line.line] : null,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  /// تخطيط التابلت: الحفاظ على نسبة العرض/الارتفاع
  Widget _buildTabletLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        const quranAspectRatio = 1000 / 1800;
        
        double contentWidth = availableWidth;
        double contentHeight = contentWidth / quranAspectRatio;
        
        if (contentHeight > availableHeight) {
          contentHeight = availableHeight;
          contentWidth = contentHeight * quranAspectRatio;
        }
        
        return Center(
          child: SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 1000,
                height: 1800,
                child: Column(
                  mainAxisAlignment: widget.page.lines.length < 13 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.spaceEvenly,
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
                        onAyahLongPress: widget.onAyahLongPress,
                        isDigital: widget.isDigital,
                        digitalWords: widget.isDigital ? _lineWordsMap[line.line] : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSurahHeader(int surahNum, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.golden.withValues(alpha: 0.1),
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

  void _showPageJumpDialog(BuildContext context) {
    final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
    final maxPages = navProvider.totalPages;
    
    showDialog(
      context: context,
      builder: (context) {
        int? selectedPage;
        return AlertDialog(
          title: const Text(
            'الانتقال إلى صفحة',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'رقم الصفحة (1-$maxPages)',
            ),
            onChanged: (value) {
              selectedPage = int.tryParse(value);
            },
            onSubmitted: (value) {
              selectedPage = int.tryParse(value);
              if (selectedPage != null && navProvider.isValidPage(selectedPage!)) {
                Navigator.pop(context);
                Provider.of<UiProvider>(context, listen: false).jumpToPage(selectedPage!);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            TextButton(
              onPressed: () {
                if (selectedPage != null && navProvider.isValidPage(selectedPage!)) {
                  Navigator.pop(context);
                  Provider.of<UiProvider>(context, listen: false).jumpToPage(selectedPage!);
                }
              },
              child: const Text('انتقال', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        );
      },
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
