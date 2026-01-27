
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/page_font_manager.dart';
import '../providers/mushaf_metadata_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import 'mushaf_selection_screen.dart';

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
    _pageController = PageController(initialPage: 0); // Default, will update
    _loadQcfCodes();
    
    // ... existing init ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quran = context.read<QuranProvider>();
      quran.loadFullQuran().then((_) {
         if (widget.initialSurahNumber != null) {
            // Logic to find page number for this surah
            // This requires Surah metadata to have 'startPage'
            // For now, we just log or try best guess if available
            final surah = quran.surahs.firstWhere(
                (s) => s.number == widget.initialSurahNumber, 
                orElse: () => quran.surahs.first
            );
            
            // Assuming we have pages in QCF view
            // In standard view, we would scroll.
            
            // For QCF PageView
            if (mounted && _pageController.hasClients) {
               // We need mapping from Surah -> Page.
               // Let's assume Surah model has it or we calculate it.
               // If Surah model doesn't have it, we default to page 0.
               // TODO: Add startPage to Surah Model
            }
         }
      });
    });
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
          final isQcf = mushafMeta.currentMushafId == 'qcf2_v4_woff2' || mushafMeta.currentMushafId.contains('qcf');
          
          return Scaffold(
             backgroundColor: settings.isDarkMode ? AppColors.darkBackground : AppColors.white,
             body: Stack(
               children: [
                 // Main Content Layer
                 GestureDetector(
                   onTap: _toggleBars,
                   child: isQcf 
                     ? _buildQcfView(quran, mushafMeta, settings)
                     : _buildStandardView(quran, settings),
                 ),

                 // Top App Bar
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

                 // Bottom Navigation Bar
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
                       _buildBottomNavItem(
                           context,
                           Icons.settings, 
                           'إعدادات', 
                           false,
                           onTap: () => Navigator.pushNamed(context, '/settings'),
                         ),
                         _buildBottomNavItem(
                           context,
                           Icons.library_books, // أو أيقونة كتب
                           'المصاحف', 
                           false,
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const MushafSelectionScreen()),
                             );
                           },
                         ),
                         _buildBottomNavItem(context, Icons.headphones, 'استماع', false),
                         _buildBottomNavItem(context, Icons.menu_book, 'تلاوة', true),
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
  
  // Standard View (ListView of Ayahs)
  Widget _buildStandardView(QuranProvider quran, SettingsProvider settings) {
      if (quran.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (quran.ayahsBySurah.isEmpty) {
        return Center(child: TextButton(onPressed: () => quran.loadFullQuran(), child: const Text("تحديث")));
      }
      
      return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100), // Padding for bars
              itemCount: quran.ayahsBySurah.length,
              itemBuilder: (context, index) {
                   // We need mapping logic here or simplify it
                   // Assuming quran.mappedSurahs and quran.ayahsBySurah are synced
                   if (index >= quran.mappedSurahs.length) return const SizedBox();
                   
                   return _buildSurahItem(quran.mappedSurahs[index], quran.ayahsBySurah[index + 1] ?? [], settings);
              }
      );
  }

  Widget _buildSurahItem(dynamic surah, List<dynamic> ayahs, SettingsProvider settings) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: AppColors.golden, width: 2)),
              ),
              child: Text(
                'سورة ${surah.nameArabic}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: settings.isDarkMode ? AppColors.golden : AppColors.darkBrown,
                ),
              ),
            ),
            
            // Basmala
            if (surah.number != 1 && surah.number != 9)
               Padding(
                 padding: const EdgeInsets.only(bottom: 16.0),
                 child: Text(
                   'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                     fontFamily: 'Amiri',
                     color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown,
                   ),
                 ),
               ),

            // Ayahs
            SelectableText.rich(
              TextSpan(
                children: ayahs.map((ayah) {
                  return TextSpan(
                    children: [
                      TextSpan(
                        text: ayah.textUthmani + ' ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: settings.fontSize,
                          color: settings.isDarkMode ? AppColors.darkText : AppColors.darkBrown,
                        ),
                      ),
                      TextSpan(
                        text: '﴿${ayah.ayahNumber}﴾ ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.golden,
                            fontSize: settings.fontSize,
                            fontFamily: 'Amiri',
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

  // QCF View (PageView of Pages)
  Widget _buildQcfView(QuranProvider quran, MushafMetadataProvider mushafMeta, SettingsProvider settings) {
      if (quran.isLoading) return const Center(child: CircularProgressIndicator());
      
      final mushaf = mushafMeta.availableMushafs.firstWhere((m) => m.identifier == mushafMeta.currentMushafId);
      final localPath = mushaf.localPath;

      if (localPath == null) {
         return Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.error_outline, size: 48, color: Colors.amber),
               const SizedBox(height: 16),
               const Text('يجب تحميل ملفات المصحف أولاً'),
               const SizedBox(height: 8),
               ElevatedButton.icon(
                 icon: const Icon(Icons.download),
                 label: const Text('تحميل الآن'),
                 onPressed: () => mushafMeta.downloadMushaf(mushaf.identifier), 
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
        reverse: true, // Arabic right-to-left
        itemCount: 604,
        key: const PageStorageKey('qcf_page_view'),
        itemBuilder: (context, pageIndex) {
          final pageNum = pageIndex + 1;
          
          return FutureBuilder(
            future: PageFontManager.instance.loadPageFont(pageNum, localPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
              }
              
              // Get Codes for this page
              // We filter _qcfCodes entries where key starts with "$pageNum:" (legacy)
              // Or better: filter by page_number if JSON structure supports it.
              // Our dummy JSON uses "1:1" format and has "page_number".
              
              final pageCodes = _qcfCodes.entries
                  .where((e) => e.value['page_number'] == pageNum)
                  .map((e) => e.value['code_v2'] as String)
                  .join(' ');
              
              // Fallback text if no JSON codes available (likely for pages > 1 in demo)
              final textToDisplay = pageCodes.isEmpty 
                  ? 'الصفحة $pageNum\n(لا توجد بيانات QCF لهذه الصفحة)' 
                  : pageCodes;
              
              final hasFont = pageCodes.isNotEmpty || snapshot.hasError == false; // Assume font loaded if no error

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      textToDisplay,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: hasFont ? PageFontManager.instance.getFontName(pageNum) : 'Amiri', // Fallback to Amiri
                        fontSize: settings.fontSize * (hasFont ? 1.5 : 1.0),
                        height: 1.6,
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
