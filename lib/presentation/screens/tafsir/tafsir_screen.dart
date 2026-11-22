import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/surah_content_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart'; // Added Import
import 'package:mathani/presentation/providers/audio_provider.dart';

class TafsirScreen extends StatefulWidget {
  final int? initialPage;

  const TafsirScreen({super.key, this.initialPage});

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

    // Listen to audio to sync Tafsir page when audio jumps to next page
    context.read<AudioProvider>().addListener(_onAudioStateChange);
  }

  void _onAudioStateChange() {
    if (!mounted) return;

    final audio = context.read<AudioProvider>();
    if (audio.isPlaying &&
        audio.currentSurah != null &&
        audio.currentAyah != null) {
      final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
      int? page;

      if (mushafId == 'shamarly_15lines') {
        final navProvider = context.read<MushafNavigationProvider>();
        page = navProvider.getPageForAyah(
          audio.currentSurah!,
          audio.currentAyah!,
        );
      } else {
        page = MushafNavigationProvider.pageForSurahAyah(
          audio.currentSurah!,
          audio.currentAyah!,
        );
      }

      if (page != null && page != _currentPage) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            page - 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    context.read<AudioProvider>().removeListener(_onAudioStateChange);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuranProvider>().updateReadingPage(_currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: settings.backgroundColor,
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
                    DropdownMenuItem(
                      value: 'muyassar',
                      child: Text('التفسير الميسر للقرآن الكريم'),
                    ),
                    DropdownMenuItem(
                      value: 'tafsir-katheer',
                      child: Text('تفسير ابن كثير'),
                    ),
                    DropdownMenuItem(
                      value: 'tafsir-saadi',
                      child: Text('تفسير السعدي'),
                    ),
                    DropdownMenuItem(
                      value: 'tafsir-baghawy',
                      child: Text('تفسير البغوي'),
                    ),
                    DropdownMenuItem(
                      value: 'tafsir-tabary',
                      child: Text('تفسير الطبري'),
                    ),
                    DropdownMenuItem(
                      value: 'eerab-aya',
                      child: Text('إعراب الآية'),
                    ),
                    DropdownMenuItem(
                      value: 'ayat-nozool',
                      child: Text('أسباب النزول'),
                    ),
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
            // Close Tafsir view explicitly
            context.read<UiProvider>().hideTafsir();
          },
        ),
        actions: const [
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
              itemCount: context.select<MushafNavigationProvider, int>(
                (p) => p.totalPages,
              ),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                return TafsirPageContent(
                  key: ValueKey('tafsir_page_${mushafId}_$pageNum'),
                  pageNumber: pageNum,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class TafsirPageContent extends StatefulWidget {
  final int pageNumber;

  const TafsirPageContent({super.key, required this.pageNumber});

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
          pageInfo.endAyah,
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        bottom: 120, // Enough bottom padding to clear the navigation bar and minibar
      ),
      itemCount: _ayahs!.length,
      itemBuilder: (context, index) {
        final ayah = _ayahs![index];
        return TafsirAyahItem(
          key: ValueKey('${ayah.surahNumber}_${ayah.ayahNumber}'),
          ayah: ayah,
        );
      },
    );
  }
}

class TafsirAyahItem extends StatefulWidget {
  final Ayah ayah;

  const TafsirAyahItem({super.key, required this.ayah});

  @override
  State<TafsirAyahItem> createState() => _TafsirAyahItemState();
}

class _TafsirAyahItemState extends State<TafsirAyahItem> {
  Future<String?>? _tafsirFuture;
  String? _currentSlug;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSlug = context.watch<SurahContentProvider>().selectedTafsirSlug;
    if (_currentSlug != newSlug) {
      _currentSlug = newSlug;
      _loadTafsir();
    }
  }

  @override
  void didUpdateWidget(TafsirAyahItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ayah.surahNumber != oldWidget.ayah.surahNumber ||
        widget.ayah.ayahNumber != oldWidget.ayah.ayahNumber) {
      _loadTafsir();
    }
  }

  void _loadTafsir() {
    final provider = context.read<SurahContentProvider>();
    setState(() {
      _tafsirFuture = provider.fetchTafsirForAyah(
        widget.ayah.surahNumber,
        widget.ayah.ayahNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
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
          // Ayah Text
          Text(
            widget.ayah.textUthmani ?? widget.ayah.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'KFGQPC_Uthmanic_Script_HAFS',
              fontSize: 20,
              height: 1.8,
              fontWeight: FontWeight.normal,
              color: Color(0xFFB71C1C), // Deep Red
            ),
          ),
          const Divider(thickness: 0.5, height: 24),

          // Tafsir Content
          FutureBuilder<String?>(
            future: _tafsirFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  'خطأ في تحميل التفسير',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                );
              }

              final content = snapshot.data;
              if (content == null || content.trim().isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _currentSlug == 'muyassar'
                        ? 'التفسير الميسر غير متوفر لهذه الآية حالياً. يرجى التأكد من تحميله في شاشة الإعدادات.'
                        : 'لا يمكن عرض التفسير. يرجى التأكد من اتصالك بالإنترنت.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              return Text(
                content,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 17,
                  color: isDark ? Colors.white70 : Colors.black,
                  height: 1.6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
