import 'package:flutter/material.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/presentation/widgets/mushaf_image_widget.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/widgets/dialogs/ayah_content_sheet.dart'; // Added
import 'package:mathani/presentation/screens/tafsir/tafsir_screen.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../../data/providers/mushaf_navigation_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/audio_minibar.dart'; // Added
import '../surah_list/surah_list_screen.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  
  const MushafScreen({
    Key? key,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final GlyphDataLoader _loader = GlyphDataLoader();
  List<PageGlyph>? _pages;
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    
    // Sync initial page with UI Provider for Tafsir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPageWithProvider(_currentPage);
      }
    });

    _loadPages();
    // Keep screen on while reading
    WakelockPlus.enable();
    
    // Listen to Audio Provider for Auto-Scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().addListener(_onAudioStateChange);
    });
  }
  
  void _onAudioStateChange() {
    if (!mounted) return;
    
    final audio = context.read<AudioProvider>();
    if (audio.isPlaying && audio.currentSurah != null && audio.currentAyah != null) {
       final navProvider = context.read<MushafNavigationProvider>();
       final page = navProvider.getPageForAyah(audio.currentSurah!, audio.currentAyah!);
       
       if (page != null && page != _currentPage) {
         // Auto Turn Page
         final targetIndex = page - 1;
         if (_pageController.hasClients) {
            _pageController.animateToPage(
              targetIndex, 
              duration: const Duration(milliseconds: 500), 
              curve: Curves.easeInOut
            );
         }
       }
       
       // Update visual highlight state
       if (_selectedSurah != audio.currentSurah || _selectedAyah != audio.currentAyah) {
         setState(() {
           _selectedSurah = audio.currentSurah;
           _selectedAyah = audio.currentAyah;
         });
       }
    }
  }
  
  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get current mushaf metadata
      final mushafProvider = context.read<MushafMetadataProvider>();
      final currentType = mushafProvider.currentMushafType;
      final currentId = mushafProvider.currentMushafId;
      
      // Get page count from metadata
      final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
      int pageCount = navProvider.totalPages;
      try {
        final mushaf = mushafProvider.availableMushafs.firstWhere((m) => m.identifier == currentId);
        pageCount = mushaf.pageCount;
      } catch (_) {}
      
      List<PageGlyph> pages;
      
      if (currentType == 'image') {
        // For image-based mushafs (like Shamarly), create dummy pages with just page numbers
        pages = List.generate(
          pageCount,
          (index) => PageGlyph(
            page: index + 1,
            lines: [], // No glyph data needed for images
          ),
        );
      } else {
        // For digital mushafs (like Madani), load actual glyph data
        pages = await _loader.loadAllPages();
      }
      
      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل المصحف: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _goToPage() {
    showDialog(
      context: context,
      builder: (context) {
        int? selectedPage;
        final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
        return AlertDialog(
                    title: const Text(
                      'الانتقال إلى صفحة',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    content: TextField(
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'رقم الصفحة (1-${navProvider.totalPages})',
                      ),
                      onChanged: (value) {
                        selectedPage = int.tryParse(value);
                      },
                      onSubmitted: (value) {
                        // Get dynamic max pages
                         final maxPages = navProvider.totalPages;
        
                        selectedPage = int.tryParse(value);
                        if (selectedPage != null && 
                            selectedPage! >= 1 && 
                            selectedPage! <= maxPages) {
                          Navigator.pop(context);
                          _pageController.jumpToPage(selectedPage! - 1);
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                      ),
            ElevatedButton(
              onPressed: () {
               // Get dynamic max pages
               final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
               final maxPages = navProvider.totalPages;

                if (selectedPage != null && 
                    selectedPage! >= 1 && 
                    selectedPage! <= maxPages) {
                  Navigator.pop(context);
                  _pageController.animateToPage(
                    selectedPage! - 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }
  // State for selected Ayah
  int? _selectedSurah;
  int? _selectedAyah;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final uiProvider = context.read<UiProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final isDark = settingsProvider.isDarkMode;
    
    if (uiProvider.isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Set status bar icon brightness based on theme
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ));
    }
  }

  void _onAyahInteraction(int surah, int ayah) {
     setState(() {
       _selectedSurah = surah;
       _selectedAyah = ayah;
     });

     showModalBottomSheet(
       context: context,
       isScrollControlled: true, // Allow full height for the sheet
       backgroundColor: Colors.transparent,
       builder: (context) => AyahContentSheet(
         surahNumber: surah,
         ayaNumber: ayah,
         wordCount: 100, // Safe default
       ),
     ).whenComplete(() {
       if (mounted) {
         setState(() {
           _selectedSurah = null;
           _selectedAyah = null;
         });
       }
     });
  }



  @override
  void dispose() {
    // Remove listener safely
    try {
      context.read<AudioProvider>().removeListener(_onAudioStateChange);
    } catch (_) {}
    
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Handle Jump Signal
    final uiProvider = Provider.of<UiProvider>(context);
    if (uiProvider.pageToJump != null) {
      final page = uiProvider.pageToJump!;
      
      // Clamp page to current mushaf limits
       final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
       final maxPages = navProvider.totalPages;
       
       final targetPage = page > maxPages ? maxPages : page;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetPage - 1);
          uiProvider.consumeJump();
        }
      });
    }
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
        appBar: AppBar(
          title: const Text(
            'المصحف الشريف',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'جاري تحميل المصحف...',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
        appBar: AppBar(
          title: const Text(
            'المصحف الشريف',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPages,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_pages == null || _pages!.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
        appBar: AppBar(
          title: const Text(
            'المصحف الشريف',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'لا توجد بيانات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
            ),
          ),
        ),
      );
    }
    
    // Calculate total pages for PageView
    int totalPages = 604;
    try {
      final provider = context.read<MushafMetadataProvider>();
      final currentId = provider.currentMushafId;
      final mushaf = provider.availableMushafs.firstWhere((m) => m.identifier == currentId);
      totalPages = mushaf.pageCount;
    } catch (_) {
      totalPages = _pages?.length ?? 604;
    }

    return Container(
      color: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
      child: Stack(
        children: [
          Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // This wrapper catching is old, sub-gestures handle it now
                },
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageView.builder(
                     controller: _pageController,
                    itemCount: totalPages,
                    reverse: false, // In RTL, standard order means reverse: false (Page 1 on right)
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index + 1;
                      });
                      _syncPageWithProvider(index + 1);
                    },

                    itemBuilder: (context, index) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent, 
                        onTap: () {
                           // Toggle immersive mode for bottom bar and system UI
                           uiProvider.toggleImmersiveMode();
                           _updateSystemUI();
                        },
                        child: Consumer<MushafMetadataProvider>(
                          builder: (context, mushafProvider, child) {
                            final currentType = mushafProvider.currentMushafType;
                            final isDigital = currentType == 'digital';
                            
                            if (currentType == 'image') {
                               final currentId = mushafProvider.currentMushafId;
                               // Find metadata safely
                               final mushaf = mushafProvider.availableMushafs.firstWhere(
                                 (m) => m.identifier == currentId,
                                 orElse: () => mushafProvider.availableMushafs.first
                               );
                               
                               return MushafImageWidget(
                                 pageNumber: _pages![index].page,
                                 mushafId: currentId,
                                 baseUrl: mushaf.baseUrl ?? '',
                                 imageExtension: mushaf.imageExtension ?? 'jpg',
                               );
                            }

                            return MushafPageWidget(
                              page: _pages![index],
                              selectedSurah: _selectedSurah,
                              selectedAyah: _selectedAyah,
                              onAyahSelected: _onAyahInteraction,
                              onAyahLongPress: _onAyahInteraction,
                              showInfo: true, // Always show top bar (Sticky)
                              isDigital: isDigital,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Audio Mini Bar
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AudioMinibar(),
        ),
      ],
      ),
    );
  }
  
  void _syncPageWithProvider(int pageNum) {
    // Sync Logic: Ensure Tafsir gets the correct "Madani" Page Number
    final navProvider = context.read<MushafNavigationProvider>();
    final pageInfo = navProvider.getPageInfo(pageNum);
    final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
    
    if (mushafId == 'shamarly_15lines' && pageInfo != null) {
       // Async translation for Shamarly
       final quranRepo = context.read<QuranProvider>();
       quranRepo.getAyah(pageInfo.startSurah, pageInfo.startAyah).then((either) {
          either.fold(
            (failure) => null, // Ignore failures
            (ayah) {
              if (ayah != null && mounted) {
                // Update UI with the STANDARD Madani page
                context.read<UiProvider>().setCurrentMushafPage(ayah.page);
                
                // Also update reading location for history
                context.read<QuranProvider>().updateReadingLocation(ayah.surahNumber, ayah.ayahNumber);
              }
            }
          );
       });
    } else {
       // Standard/Madani: 1-to-1 mapping
       context.read<UiProvider>().setCurrentMushafPage(pageNum);
       
       // Update Reading Location Logic for Madani (Dynamic & Fast)
       if (pageInfo != null && pageInfo.startSurah > 0) {
          final surah = pageInfo.startSurah;
          final ayah = pageInfo.startAyah > 0 ? pageInfo.startAyah : 1;
          
          context.read<QuranProvider>().updateReadingLocation(surah, ayah);
          
          // Audio Context Awareness: Update audio context without playing
          context.read<AudioProvider>().setContext(surah, ayah);
       }
    }
  }
}
