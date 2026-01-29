
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
import 'widgets/ayah_widget.dart';
import 'widgets/surah_header.dart';
import 'widgets/basmala_widget.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/get_metadata_usecase.dart';

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

  Map<int, int> _surahToPage = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadQcfCodes();
    _loadSurahPageMap();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quran = context.read<QuranProvider>();
      quran.loadFullQuran().then((_) {
         if (widget.initialSurahNumber != null) {
            _navigateToSurah(widget.initialSurahNumber!);
         }
      });
    });
  }

  Future<void> _loadSurahPageMap() async {
    final useCase = sl<GetSurahPageMapUseCase>();
    final result = await useCase();
    result.fold(
      (failure) => debugPrint('Error loading surah map: ${failure.message}'),
      (map) => setState(() => _surahToPage = map),
    );
  }
  
  void _navigateToSurah(int surahNumber) {
    // استخدام الخريطة المحملة من JSON
    final targetPage = _surahToPage[surahNumber] ?? 1;
    
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
                  return AyahWidget(
                    number: ayah.ayahNumber,
                    text: ayah.textUthmani,
                  ).buildSpan(context);
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
