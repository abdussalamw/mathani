import 'package:flutter/material.dart';
import '../../data/models/page_glyph.dart';
import '../../data/models/ayah.dart';
import '../../core/constants/app_colors.dart';
import 'page_line_widget.dart';
import 'dart:collection';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/qcf4_font_downloader.dart';
import '../../data/services/qpc_v1_font_downloader.dart'; // Added
import '../../data/services/qpc_v1_data_service.dart'; // Added
import '../../data/services/qpc_v1_layout_service.dart'; // Fixed: Added missing import
import '../../presentation/providers/quran_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/bookmark_provider.dart';
import '../../presentation/providers/ui_provider.dart';
import '../../data/providers/mushaf_navigation_provider.dart';
import '../../presentation/providers/audio_provider.dart'; // Added
import '../../core/constants/responsive_constants.dart';

/// Widget لعرض صفحة كاملة من المصحف
class MushafPageWidget extends StatefulWidget {
  final PageGlyph page;
  final int? selectedSurah;
  final int? selectedAyah;
  final Function(int surah, int ayah)? onAyahSelected;
  final Function(int surah, int ayah)? onAyahLongPress;
  final bool showInfo;
  final bool isDigital;
  
  final String? mushafId; // Added to distinguish between QCF4 and QPC V1
  
  const MushafPageWidget({
    Key? key,
    required this.page,
    this.mushafId,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahSelected,
    this.onAyahLongPress,
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
  Map<int, List<String>> _lineWordsMap = {};

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
    if (oldWidget.page.page != widget.page.page || oldWidget.isDigital != widget.isDigital || oldWidget.mushafId != widget.mushafId) {
      _loadData();
    }
  }

  // Store V1 Lines specifically
  List<V1Line>? _v1Lines;

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoadingDigital = true);
    
    try {
      final isV1 = widget.mushafId == 'madani_old_v1';
      
      // Load standard Ayahs (V4 Mapping) purely for accessibility/tafsir fallback
      final ayahs = await context.read<QuranProvider>().getAyahsForPage(widget.page.page);
      
      if (isV1) {
         // Load QPC V1 Layout
         try {
           _v1Lines = await QPCV1LayoutService().getLinesForPage(widget.page.page);
         } catch(e) {
           debugPrint('V1 Layout Load Error: $e');
         }
      } else {
         _v1Lines = null;
      }
      
      if (mounted) {
        setState(() {
          _digitalAyahs = ayahs;
          if (widget.isDigital || isV1) {
            _mapWords();
            _isFontLoaded = true;
          }
          _isLoadingDigital = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading page metadata: $e');
      if (mounted) setState(() => _isLoadingDigital = false);
    }
    
    if (!widget.isDigital) {
      bool loaded = false;
      if (widget.mushafId == 'madani_old_v1') {
         loaded = await QPCV1FontDownloader.loadPageFont(widget.page.page);
      } else {
         loaded = await QCF4FontDownloader.loadPageFont(widget.page.page);
      }
      
      if (mounted) {
        setState(() {
          _isFontLoaded = loaded;
        });
      }
    }
  }

  void _mapWords() {
    _lineWordsMap.clear();
    final bool isV1 = widget.mushafId == 'madani_old_v1';

    if (isV1 && _v1Lines != null) {
       // V1 Strict Layout
       for (var line in _v1Lines!) {
          if (line.isSurahHeader) {
             _lineWordsMap[line.lineNumber] = []; 
             continue;
          }
          if (line.isBasmala) {
             _lineWordsMap[line.lineNumber] = [line.text]; 
             continue;
          }
          // PUA Text
          _lineWordsMap[line.lineNumber] = [line.text];
       }
       return;
    }

    // Standard V4 Logic
    if (_digitalAyahs == null) return;
    
    final Queue<String> wordQueue = Queue();
    for (var ayah in _digitalAyahs!) {
       final words = ayah.text.split(' ').where((w) => w.isNotEmpty).toList();
       wordQueue.addAll(words);
    }

    for (var line in widget.page.lines) {
       List<String> currentLineWords = [];
       for (var glyph in line.glyphs) {
          if (glyph.isWord) {
             if (wordQueue.isNotEmpty) {
                currentLineWords.add(wordQueue.removeFirst());
             } else {
                currentLineWords.add('(?)');
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
    final topBarHeight = ResponsiveConstants.getTopBarHeight(context);
    
    return Container(
      decoration: BoxDecoration(
        color: settings.backgroundColor,
        image: (isDark || settings.backgroundColorMode == 'white') ? null : const DecorationImage(
          image: AssetImage('assets/images/mushaf_texture.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Column(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.showInfo ? 1.0 : 0.0,
            child: SizedBox(
              height: topBarHeight,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Right Side: Juz Name
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Consumer<MushafNavigationProvider>(
                            builder: (context, navProvider, child) {
                              final pageInfo = navProvider.getPageInfo(widget.page.page);
                              final juzNumber = pageInfo?.juz ?? 1;
                              final int juzCodePoint = 0xF1D8 + (juzNumber - 1);
                              return InkWell(
                                onTap: () {
                                  Provider.of<UiProvider>(context, listen: false).setTabIndex(0, indexScreenTab: 1);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    String.fromCharCode(juzCodePoint),
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

                      // Center: Surah Name
                      Expanded(
                        child: Center(
                          child: Consumer<MushafNavigationProvider>(
                            builder: (context, navProvider, child) {
                              final pageInfo = navProvider.getPageInfo(widget.page.page);
                              final surahs = pageInfo?.surahs ?? [];
                              final surahNumber = surahs.isNotEmpty ? surahs.first : null;
                              if (surahNumber != null) {
                                final int surahCodePoint = 0xF100 + (surahNumber - 1);
                                return InkWell(
                                  onTap: () {
                                    Provider.of<UiProvider>(context, listen: false).setTabIndex(0);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      String.fromCharCode(surahCodePoint),
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
                      
                      // Left Side: Icons + Page Number
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),

                              // Dark Mode Toggle
                              InkWell(
                                onTap: () => settings.toggleDarkMode(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4), 
                                  child: Icon(
                                    isDark ? Icons.light_mode : Icons.dark_mode,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),


                              // Bookmark Toggle
                              Consumer<BookmarkProvider>(
                                builder: (context, bookmarks, child) {
                                  int? targetSurah, targetAyah;
                                  if (_digitalAyahs != null && _digitalAyahs!.isNotEmpty) {
                                     targetSurah = _digitalAyahs!.first.surahNumber;
                                     targetAyah = _digitalAyahs!.first.ayahNumber;
                                  } else if (widget.page.lines.isNotEmpty) {
                                     for (var g in widget.page.lines.first.glyphs) {
                                        if (g.surah != null && g.ayah != null) {
                                           targetSurah = g.surah;
                                           targetAyah = g.ayah;
                                           break;
                                        }
                                     }
                                  }
                                  final isBookmarked = targetSurah != null && targetAyah != null && bookmarks.isBookmarked(targetSurah, targetAyah);
                                  return InkWell(
                                    onTap: () {
                                       if (targetSurah != null && targetAyah != null) {
                                          if (isBookmarked) {
                                             bookmarks.removeBookmark(targetSurah, targetAyah);
                                          } else {
                                             bookmarks.addBookmark(targetSurah, targetAyah, note: 'صفحة ${widget.page.page}');
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
                              InkWell(
                                onTap: () => _showPageJumpDialog(context),
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
          
          // 2. Content
          Expanded(
            child: Center(
              child: SizedBox(
                width: ResponsiveConstants.getContentHeight(context) * 0.8,
                child: widget.isDigital && _isLoadingDigital
                    ? const Center(child: CircularProgressIndicator()) 
                    : (!_isFontLoaded 
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            padding: EdgeInsets.only(
                               top: ResponsiveConstants.safetyMarginTop, 
                               bottom: ResponsiveConstants.getBottomBarHeight(context) + ResponsiveConstants.safetyMarginBottom, 
                               left: 16, 
                               right: 16
                            ),
                            child: ResponsiveConstants.getDeviceType(context) == DeviceType.mobile
                                ? _buildMobileLayout()
                                : _buildTabletLayout(),
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: widget.page.lines.length < 10 
          ? MainAxisAlignment.spaceEvenly 
          : (widget.page.lines.length < 13 
              ? MainAxisAlignment.center 
              : MainAxisAlignment.spaceEvenly),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.page.lines.map((line) {
        final verticalPadding = widget.page.lines.length < 10 ? 16.0 : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
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
                mushafId: widget.mushafId, // Pass ID
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
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
                  mainAxisAlignment: widget.page.lines.length < 10 
                      ? MainAxisAlignment.spaceEvenly 
                      : (widget.page.lines.length < 13 
                          ? MainAxisAlignment.center 
                          : MainAxisAlignment.spaceEvenly),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.page.lines.map((line) {
                    final verticalPadding = widget.page.lines.length < 10 ? 24.0 : 0.0;
                    return Container(
                      padding: widget.page.lines.length < 13 
                          ? EdgeInsets.symmetric(vertical: verticalPadding > 0 ? verticalPadding : 12.0) 
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
                        mushafId: widget.mushafId, // Pass ID
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

  void _showPageJumpDialog(BuildContext context) {
    final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
    final maxPages = navProvider.totalPages;
    showDialog(
      context: context,
      builder: (context) {
        int? selectedPage;
        return AlertDialog(
          title: const Text('الانتقال إلى صفحة', style: TextStyle(fontFamily: 'Tajawal')),
          content: TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(hintText: 'رقم الصفحة (1-$maxPages)'),
            onChanged: (value) => selectedPage = int.tryParse(value),
            onSubmitted: (value) {
              selectedPage = int.tryParse(value);
              if (selectedPage != null && navProvider.isValidPage(selectedPage!)) {
                Navigator.pop(context);
                Provider.of<UiProvider>(context, listen: false).jumpToPage(selectedPage!);
              }
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                if (selectedPage != null && navProvider.isValidPage(selectedPage!)) {
                  Navigator.pop(context);
                  Provider.of<UiProvider>(context, listen: false).jumpToPage(selectedPage!);
                }
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  String _convertToArabicNumbers(int number) {
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
