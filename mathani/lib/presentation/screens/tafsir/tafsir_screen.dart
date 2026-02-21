import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/surah_content_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart'; // Added Import

class TafsirScreen extends StatefulWidget {
  final int? initialPage;
  
  const TafsirScreen({Key? key, this.initialPage}) : super(key: key);

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  late PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Default to provider's page if not passed
    final quran = context.read<QuranProvider>();
    _currentPage = widget.initialPage ?? quran.readingPage;
    if (_currentPage == 0) _currentPage = 1;
    
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TafsirScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPage != null && widget.initialPage != oldWidget.initialPage) {
      final newPage = widget.initialPage!;
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(newPage - 1);
        }
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1;
    });
    context.read<QuranProvider>().updateReadingPage(_currentPage);
  }

  void _showTafsirSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<SurahContentProvider>(
          builder: (context, provider, _) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'اختر التفسير',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    {'slug': 'w-moyassar', 'name': 'التفسير الميسر للقرآن الكريم'},
                    {'slug': 'tafsir-katheer', 'name': 'تفسير ابن كثير'},
                    {'slug': 'tafsir-saadi', 'name': 'تفسير السعدي'},
                    {'slug': 'tafsir-baghawy', 'name': 'تفسير البغوي'},
                    {'slug': 'tafsir-tabary', 'name': 'تفسير الطبري'},
                    {'slug': 'eerab-aya', 'name': 'إعراب الآية'},
                    {'slug': 'ayat-nozool', 'name': 'أسباب النزول'},
                  ].map((item) => ListTile(
                    title: Text(item['name']!, style: const TextStyle(fontFamily: 'Tajawal')),
                    trailing: provider.selectedTafsirSlug == item['slug'] 
                      ? const Icon(Icons.check, color: AppColors.primary) 
                      : null,
                    onTap: () {
                      provider.changeTafsir(item['slug']!);
                      Navigator.pop(context);
                      setState(() {}); // Rebuild to refresh content
                    },
                  )).toList(),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to external page changes (e.g. from Mushaf) ONLY if not navigating internally?
    // Actually, simple way: Just use PageView.
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1410) : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Consumer<SurahContentProvider>(
          builder: (context, provider, _) {
            // Dropdown for Tafsir Selection directly in AppBar
            return Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.selectedTafsirSlug,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  isDense: true,
                  alignment: Alignment.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                  ),
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'w-moyassar', child: Text('التفسير الميسر للقرآن الكريم')),
                    DropdownMenuItem(value: 'tafsir-katheer', child: Text('تفسير ابن كثير')),
                    DropdownMenuItem(value: 'tafsir-saadi', child: Text('تفسير السعدي')),
                    DropdownMenuItem(value: 'tafsir-baghawy', child: Text('تفسير البغوي')),
                    DropdownMenuItem(value: 'tafsir-tabary', child: Text('تفسير الطبري')),
                    DropdownMenuItem(value: 'eerab-aya', child: Text('إعراب الآية')),
                    DropdownMenuItem(value: 'ayat-nozool', child: Text('أسباب النزول')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.changeTafsir(val);
                      setState(() {});
                    }
                  },
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            // Switch back to Mushaf Tab
            context.read<UiProvider>().setTabIndex(1);
          },
        ),
        actions: [
          // Keep existing actions if any, or remove generic menu
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<MushafMetadataProvider>(
          builder: (context, mushafProvider, _) {
            final mushafId = mushafProvider.currentMushafId;
            return PageView.builder(
              controller: _pageController,
              itemCount: context.select<MushafNavigationProvider, int>((p) => p.totalPages),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                return TafsirPageContent(
                  key: ValueKey('tafsir_page_${mushafId}_$pageNum'), 
                  pageNumber: pageNum
                );
              },
            );
          }
        ),
      ),
    );
  }
}

class TafsirPageContent extends StatefulWidget {
  final int pageNumber;
  
  const TafsirPageContent({Key? key, required this.pageNumber}) : super(key: key);

  @override
  State<TafsirPageContent> createState() => _TafsirPageContentState();
}

class _TafsirPageContentState extends State<TafsirPageContent> {
  List<Ayah>? _ayahs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAyahs();
  }

  @override
  void didUpdateWidget(TafsirPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageNumber != oldWidget.pageNumber) {
      _loadAyahs();
    }
  }

  Future<void> _loadAyahs() async {
    setState(() => _isLoading = true);
    final quran = context.read<QuranProvider>();
    final navProvider = context.read<MushafNavigationProvider>();
    final mushafProvider = context.read<MushafMetadataProvider>();
    
    final mushafId = mushafProvider.currentMushafId;
    List<Ayah> ayahs = [];
    
    if (mushafId == 'shamarly_15lines') {
      final pageInfo = navProvider.getPageInfo(widget.pageNumber);
      if (pageInfo != null && pageInfo.startSurah > 0) {
        // Fetch by specific range mapped from Shamarly Navigation Data
        ayahs = await quran.getAyahsByRange(
          pageInfo.startSurah, 
          pageInfo.startAyah, 
          pageInfo.endSurah, 
          pageInfo.endAyah
        );
      }
    } else {
      // Default to Madani 604 page mapping attached to the Isar DB
      ayahs = await quran.getAyahsForPage(widget.pageNumber);
    }
    
    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_ayahs == null || _ayahs!.isEmpty) {
      return const Center(child: Text('لا توجد آيات لهذه الصفحة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ayahs!.length,
      itemBuilder: (context, index) {
        final ayah = _ayahs![index];
        return TafsirAyahItem(ayah: ayah);
      },
    );
  }
}

class TafsirAyahItem extends StatefulWidget {
  final Ayah ayah;
  
  const TafsirAyahItem({Key? key, required this.ayah}) : super(key: key);

  @override
  State<TafsirAyahItem> createState() => _TafsirAyahItemState();
}

class _TafsirAyahItemState extends State<TafsirAyahItem> {
  @override
  void initState() {
    super.initState();
    // Fetch content
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final provider = context.read<SurahContentProvider>();
       if (provider.selectedTafsirSlug.isEmpty) {
         provider.setTafsirSlug('w-moyassar');
       }
       // We need a specific fetch for this item, NOT affecting the global 'current' one?
       // SurahContentProvider currently stores 'currentAyaContent'. 
       // If we use it for a LIST, it will overwrite each other!
       // Use a FutureBuilder with DIRECT API SERVICE call or method in provider that returns Future.
    });
  }

  @override
  Widget build(BuildContext context) {
     // User Request: Make font 300% smaller. 
     // Default was 20. 300% smaller -> 1/3 -> ~7? Too small. 
     // User probably means "Literally very small". Let's try 12 or 10.
     // Standard body is 14-16. 
     // Let's use 12 for now.
     
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final quran = context.read<QuranProvider>();
    final surahName = quran.surahs
      .firstWhere((s) => s.number == widget.ayah.surahNumber, orElse: () => quran.surahs.first) 
      .nameArabic;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2416) : Colors.white,
        borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.05),
             blurRadius: 4,
             offset: const Offset(0, 2),
           ),
         ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah Header REMOVED as per request
          
          // Ayah Text
          Text(
            widget.ayah.text,
            textAlign: TextAlign.center,
             textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs_V22', // Updated to use the new font here too!
              fontSize: 22,
              height: 1.6,
              fontWeight: FontWeight.normal,
              color: AppColors.golden, // GOLD per request
            ),
          ),
          const Divider(thickness: 0.5, height: 24),
          
          // Tafsir Content (Fetch locally via Provider helper or Service)
          Consumer<SurahContentProvider>(
            builder: (context, provider, _) {
               return FutureBuilder(
                 future: provider.fetchTafsirForAyah(widget.ayah.surahNumber, widget.ayah.ayahNumber),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                   }
                   if (snapshot.hasError) {
                     return const Text('خطأ في تحميل التفسير', style: TextStyle(fontSize: 10, color: Colors.red));
                   }
                   
                   final content = snapshot.data as String?;
                   if (content == null) return const SizedBox();

                   return Text(
                     content,
                     textAlign: TextAlign.justify,
                     textDirection: TextDirection.rtl,
                     style: TextStyle(
                       fontFamily: 'Amiri', // Or Tajawal?
                       fontSize: 16, // Adjusted for readability
                       color: isDark ? Colors.white70 : Colors.black, // BLACK per request (adjusted for dark mode)
                       height: 1.6,
                     ),
                   );
                 },
               );
            },
          ),
        ],
      ),
    );
  }
}
