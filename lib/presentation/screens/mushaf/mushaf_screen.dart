
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/collections.dart';
import '../../../core/utils/page_font_manager.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/settings_provider.dart';
import 'mushaf_selection_screen.dart';
import 'widgets/surah_header.dart';
import 'widgets/basmala_widget.dart';

class MushafScreen extends StatefulWidget {
  final int? initialSurahNumber;
  const MushafScreen({Key? key, this.initialSurahNumber}) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  bool _showBars = true;
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  Map<String, dynamic> _qcfCodes = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadQcfCodes();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quran = context.read<QuranProvider>();
      quran.loadFullQuran().then((_) {
         if (widget.initialSurahNumber != null) {
            _navigateToSurah(widget.initialSurahNumber!);
         }
      });
    });
  }
  
  void _navigateToSurah(int surahNumber) {
    // خريطة صفحات بداية السور (تقريبية لمصحف المدينة)
    final Map<int, int> surahToPage = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
      11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
      21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
      31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
      41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
      61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
      71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
      81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
      91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599, 100: 599,
      101: 600, 102: 600, 103: 601, 104: 601, 105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603,
      111: 603, 112: 604, 113: 604, 114: 604
    };

    final targetPage = surahToPage[surahNumber] ?? 1;
    
    if (_pageController.hasClients) {
       _pageController.jumpToPage(targetPage - 1);
    } else {
       Future.delayed(const Duration(milliseconds: 300), () {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetPage - 1);
          }
       });
    }
  }
  
  void _toggleBars() {
    setState(() => _showBars = !_showBars);
  }

  Future<void> _loadQcfCodes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran_qcf2_codes.json');
      setState(() {
        _qcfCodes = json.decode(jsonString);
      });
    } catch (e) {
      debugPrint('Error loading QCF codes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<QuranProvider, SettingsProvider, MushafMetadataProvider>(
      builder: (context, quran, settings, mushafMeta, _) {
          final isQcf = mushafMeta.currentMushafId.contains('qcf') || mushafMeta.currentMushafId.contains('image');
          
          if (quran.jumpToSurahNumber != null) {
             final surahNum = quran.jumpToSurahNumber!;
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 _navigateToSurah(surahNum);
                 quran.clearJump();
             });
          }

          return Scaffold(
             backgroundColor: settings.isDarkMode ? AppColors.darkBackground : const Color(0xFFFFF8E1),
             body: Stack(
               children: [
                 GestureDetector(
                   onTap: _toggleBars,
                   child: isQcf 
                     ? _buildQcfView(quran, mushafMeta, settings)
                     : _buildStandardView(quran, settings),
                 ),

                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 300),
                   top: _showBars ? 0 : -100,
                   left: 0,
                   right: 0,
                   child: AppBar(
                     backgroundColor: (settings.isDarkMode ? AppColors.darkSurface : AppColors.white).withOpacity(0.95),
                     elevation: 4,
                     title: Text(
                       'المصحف الشريف',
                       style: TextStyle(
                         color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown,
                         fontFamily: 'Tajawal',
                         fontWeight: FontWeight.bold
                       )
                     ),
                     centerTitle: true,
                     iconTheme: IconThemeData(
                       color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown
                     ),
                     actions: [
                       IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                       IconButton(icon: const Icon(Icons.bookmark_outline), onPressed: () {}),
                     ],
                   ),
                 ),

                 AnimatedPositioned(
                   duration: const Duration(milliseconds: 300),
                   bottom: _showBars ? 0 : -100,
                   left: 0,
                   right: 0,
                   child: Container(
                     decoration: BoxDecoration(
                       color: (settings.isDarkMode ? AppColors.darkSurface : AppColors.white).withOpacity(0.95),
                       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
                     ),
                     padding: const EdgeInsets.symmetric(vertical: 8),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
                         IconButton(icon: const Icon(Icons.library_books), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MushafSelectionScreen()))),
                       ],
                     ),
                   ),
                 ),
               ],
             )
          );
      }
    );
  }
  
  Widget _buildStandardView(QuranProvider quran, SettingsProvider settings) {
      if (quran.isLoading) return const Center(child: CircularProgressIndicator());
      if (quran.ayahs.isEmpty) {
         quran.loadFullQuran();
         return const Center(child: CircularProgressIndicator());
      }
      
      return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100), 
              itemCount: quran.mappedSurahs.length,
              itemBuilder: (context, index) {
                   final surah = quran.mappedSurahs[index];
                   final ayahs = quran.ayahsBySurah[surah.number] ?? [];
                   if (ayahs.isEmpty) return const SizedBox();

                   return _buildSurahItem(surah, ayahs, settings);
              }
      );
  }

  Widget _buildQcfView(QuranProvider quran, MushafMetadataProvider mushafMeta, SettingsProvider settings) {
      if (quran.isLoading) return const Center(child: CircularProgressIndicator());
      
      final mushaf = mushafMeta.availableMushafs.firstWhere((m) => m.identifier == mushafMeta.currentMushafId, orElse: () => mushafMeta.availableMushafs.first);
      final localPath = mushaf.localPath;

      if (localPath == null) {
         return Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.file_download_off, size: 48, color: Colors.amber),
               const SizedBox(height: 16),
               const Text('يجب تحميل ملفات هذا المصحف أولاً لعرضه'),
               const SizedBox(height: 8),
               ElevatedButton.icon(
                 icon: const Icon(Icons.download),
                 label: const Text('تحميل البيانات (خطوط وصفحات)'),
                 onPressed: () => mushafMeta.downloadMushaf(mushaf.identifier!), 
               )
             ],
           )
         );
      }
      
      if (mushafMeta.isDownloading && mushafMeta.currentDownloadingId == mushaf.identifier) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('جاري التحميل... ${(mushafMeta.downloadProgress * 100).toInt()}%'),
              ],
            ),
          );
      }

      return PageView.builder(
        controller: _pageController,
        reverse: true,
        itemCount: 604, 
        key: const PageStorageKey('qcf_page_view'),
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          
          return FutureBuilder(
            future: PageFontManager.instance.loadPageFont(pageNum, localPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              
              String? pageText;
              final pageEntry = _qcfCodes.values.firstWhere(
                 (v) => v['page_number'] == pageNum,
                 orElse: () => null
              );
              
              if (pageEntry != null) {
                 pageText = pageEntry['code_v2'] as String?;
              }
              
              final bool isFallback = pageText == null || pageText.isEmpty;
              if (isFallback) {
                  return FutureBuilder<List<dynamic>>(
                     future: quran.getAyahsForPage(pageNum),
                     builder: (context, textSnapshot) {
                        if (!textSnapshot.hasData || textSnapshot.data!.isEmpty) return const SizedBox();
                        
                        final ayahs = textSnapshot.data!;
                        final combinedText = ayahs.map((a) => '${a.textUthmani} ﴿${a.ayahNumber}﴾').join(' ');
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            child: Text(
                              combinedText,
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'HafsSmart', // الخط الجديد
                                fontSize: settings.fontSize * 1.25,
                                height: 1.9,
                                color: settings.isDarkMode ? AppColors.darkText : Colors.black,
                              ),
                            ),
                          ),
                        );
                     }
                  );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      pageText!,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: PageFontManager.instance.getFontName(pageNum),
                        fontSize: settings.fontSize * 1.2,
                        height: 1.5,
                        color: settings.isDarkMode ? AppColors.darkText : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
  }

  Widget _buildSurahItem(dynamic surah, List<dynamic> ayahs, SettingsProvider settings) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          children: [
            SurahHeader(title: 'سورة ${surah.nameArabic}'),
            
            if (surah.number != 1 && surah.number != 9)
               const BasmalaWidget(),

            SelectableText.rich(
              TextSpan(
                children: ayahs.map((ayah) {
                  return TextSpan(
                    children: [
                      TextSpan(
                        text: ayah.textUthmani + ' ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'HafsSmart', // الخط الجديد
                          fontSize: settings.fontSize * 1.25,
                          height: 1.9,
                          color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown,
                        ),
                      ),
                      TextSpan(
                        text: '﴿${ayah.ayahNumber}﴾ ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.golden,
                            fontSize: settings.fontSize,
                            fontFamily: 'HafsSmart', // الخط الجديد
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
     );
  }

  Widget _buildBottomNavItem(BuildContext context, IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.greyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.greyMedium,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
