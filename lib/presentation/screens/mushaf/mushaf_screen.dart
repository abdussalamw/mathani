import 'package:flutter/material.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/presentation/widgets/mushaf_image_widget.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/widgets/dialogs/ayah_content_sheet.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../../data/providers/mushaf_navigation_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/recitation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/audio_minibar.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mathani/core/constants/responsive_constants.dart';
import 'dart:async';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  
  const MushafScreen({
    Key? key,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

/// ScrollPhysics ظ…ط®طµطµ ظ„ط¶ظ…ط§ظ† ط§ظ„طھظ†ظ‚ظ„ ط¨ظٹظ† ط§ظ„طµظپط­ط§طھ ط¨ط¯ظ‚ط© (طµظپط­ط© ظˆط§ط­ط¯ط© ظ„ظƒظ„ طھظ…ط±ظٹط±ط©)
class SensitivePageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;
  final double flingVelocity;

  const SensitivePageScrollPhysics({
    ScrollPhysics? parent,
    this.dragThreshold = 10.0, // عتبة سحب منخفضة — يتبع الإصبع مبكراً وتقليب أسهل بسحبة أصغر
    this.flingVelocity = 90.0, // قذف أسهل — لمسة/سحبة خفيفة تكفي للانتقال
  }) : super(parent: parent);

  @override
  SensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SensitivePageScrollPhysics(
      parent: buildParent(ancestor),
      dragThreshold: dragThreshold,
      flingVelocity: flingVelocity,
    );
  }

  @override
  double get dragStartDistanceMotionThreshold => dragThreshold;
  
  @override
  double get minFlingVelocity => flingVelocity;
}

class _MushafScreenState extends State<MushafScreen> with TickerProviderStateMixin {
  final GlyphDataLoader _loader = GlyphDataLoader();
  List<PageGlyph>? _pages;
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;
  int _currentPage = 1;
  String? _loadedMushafId;


  // Auto Scroll State
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  bool _isAutoScrollPaused = false; // للإيقاف المؤقت بضغطة واحدة
  static const double _autoScrollMaxSpeed = 0.22; // ~13 بكسل/ث — صفحة (~800-900px) تُنجز في ~دقيقة
  static const Duration _autoScrollInterval = Duration(milliseconds: 16); // ~60fps
  static const Duration _autoScrollRampDuration = Duration(seconds: 5); // تسارع أطول وناعم (بدون قفزة)
  static const double _autoScrollSlowdownStart = 0.15; // بدء التباطؤ السلس في آخر 15% من المحتوى
  DateTime? _autoScrollStartTime; // وقت بدء التمرير
  
  // ScrollControllers ظ„ظ„طµظپط­ط§طھ ط§ظ„ظپط±ط¯ظٹط© (ظ„ظ„ظˆط¶ط¹ Hybrid)
  final Map<int, ScrollController> _innerScrollControllers = {};
  
  // Bi-directional Drag State (للتنقل ثنائي الأبعاد)
  final ValueNotifier<double> _secondaryOffsetNotifier = ValueNotifier(0.0);
  bool _isSecondaryDragging = false;
  int? _secondaryTargetPage;
  // Cache pages for smooth dragging without rebuilds
  Widget? _cachedCurrentPageWidget;
  Widget? _cachedTargetPageWidget;
  late AnimationController _secondaryAnimController;
  
  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _pageController.addListener(_onScroll);
    
    _secondaryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380), // Smoother secondary swipe
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPageWithProvider(_currentPage);
      }
    });

    _loadPages();
    WakelockPlus.enable();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_audioListenerAdded) {
        context.read<AudioProvider>().addListener(_onAudioStateChange);
        _audioListenerAdded = true;
      }
      if (!_recitationListenerAdded) {
        context.read<RecitationProvider>().addListener(_onRecitationStateChange);
        _recitationListenerAdded = true;
      }
    });
  }
  
  void _onAudioStateChange() {
    if (!mounted) return;
    
    final audio = context.read<AudioProvider>();
    if (audio.isPlaying && audio.currentSurah != null && audio.currentAyah != null) {
       final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
       int? page;
       
       if (mushafId == 'shamarly_15lines') {
         final navProvider = context.read<MushafNavigationProvider>();
         page = navProvider.getPageForAyah(audio.currentSurah!, audio.currentAyah!);
       } else {
         // Madani uses the precise statically hardcoded 604-page mapping
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
              curve: Curves.easeInOut
            );
         }
       }
       
       if (_selectedSurah != audio.currentSurah || _selectedAyah != audio.currentAyah) {
         setState(() {
           _selectedSurah = audio.currentSurah;
           _selectedAyah = audio.currentAyah;
         });
       }
    }
  }

  void _onRecitationStateChange() {
    if (!mounted) return;
    
    final recitation = context.read<RecitationProvider>();
    final uiProvider = context.read<UiProvider>();
    
    if (uiProvider.isRecitationActive) {
      if (recitation.matchedSurah != null && recitation.matchedAyah != null) {
        final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
        int? page;
        
        if (mushafId == 'shamarly_15lines') {
          final navProvider = context.read<MushafNavigationProvider>();
          page = navProvider.getPageForAyah(recitation.matchedSurah!, recitation.matchedAyah!);
        } else {
          page = MushafNavigationProvider.pageForSurahAyah(
            recitation.matchedSurah!, 
            recitation.matchedAyah!,
          );
        }
        
        if (page != null && page != _currentPage) {
          if (_pageController.hasClients) {
             _pageController.animateToPage(
               page - 1, 
               duration: const Duration(milliseconds: 500), 
               curve: Curves.easeInOut
             );
          }
        }
        
        _selectedSurah = recitation.matchedSurah;
        _selectedAyah = recitation.matchedAyah;
      }
      setState(() {});
    } else {
      if (_selectedSurah != null || _selectedAyah != null) {
        final audio = context.read<AudioProvider>();
        if (!audio.isPlaying) {
          setState(() {
            _selectedSurah = null;
            _selectedAyah = null;
          });
        }
      }
    }
  }
  
  void _onScroll() {
    if (!mounted || _isLoading) return;
    final settings = context.read<SettingsProvider>();
    if (settings.isVerticalContinuousMode && _pageController.hasClients) {
      final viewportHeight = _pageController.position.viewportDimension;
      if (viewportHeight > 0) {
        final topOffset = _pageController.offset + ResponsiveConstants.getTopBarHeight(context);
        final topPage = (topOffset / viewportHeight).floor() + 1;
        if (topPage != _currentPage && topPage >= 1 && topPage <= (_pages?.length ?? 604)) {
          // دمج المزامنة بتردد محدود لتجنّب إعادة بناء الشاشة مع كل بكسل (سلاسة الوضع المستمر)
          _debouncedContinuousPageSync(topPage);
        }
      }
    }
  }

  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final mushafProvider = context.read<MushafMetadataProvider>();
      final currentType = mushafProvider.currentMushafType;
      final currentId = mushafProvider.currentMushafId;
      
      final navProvider = Provider.of<MushafNavigationProvider>(context, listen: false);
      int pageCount = navProvider.totalPages;
      try {
        final mushaf = mushafProvider.availableMushafs.firstWhere((m) => m.identifier == currentId);
        pageCount = mushaf.pageCount;
      } catch (_) {}
      
      List<PageGlyph> pages;
      
      if (currentType != 'font_v2') {
        pages = List.generate(
          pageCount,
          (index) => PageGlyph(
            page: index + 1,
            lines: [],
          ),
        );
      } else {
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
          _errorMessage = 'ظپط´ظ„ طھط­ظ…ظٹظ„ ط§ظ„ظ…طµط­ظپ: $e';
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
            'ط§ظ„ط§ظ†طھظ‚ط§ظ„ ط¥ظ„ظ‰ طµظپط­ط©',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'ط±ظ‚ظ… ط§ظ„طµظپط­ط© (1-${navProvider.totalPages})',
            ),
            onChanged: (value) {
              selectedPage = int.tryParse(value);
            },
            onSubmitted: (value) {
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
              child: const Text('ط¥ظ„ط؛ط§ط،', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              onPressed: () {
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
              child: const Text('ط§ظ†طھظ‚ط§ظ„'),
            ),
          ],
        );
      },
    );
  }
  
  int? _selectedSurah;
  int? _selectedAyah;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
    
    // Listen to Mushaf change
    final mushafProvider = Provider.of<MushafMetadataProvider>(context);
    final currentId = mushafProvider.currentMushafId;
    
    if (_loadedMushafId != currentId) {
       _loadedMushafId = currentId;
       // We delayed to avoid calling setState during build if triggered by build
       Future.microtask(() => _loadPages());
    }
  }

  void _updateSystemUI() {
    final uiProvider = context.read<UiProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final isDark = settingsProvider.isDarkMode;
    
    if (uiProvider.isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (context) => AyahContentSheet(
         surahNumber: surah,
         ayaNumber: ayah,
         wordCount: 100,
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

  // ط´ط±ظٹط· ط¹ظ„ظˆظٹ ط«ط§ط¨طھ ظ„ظ„ظˆط¶ط¹ ط§ظ„ظ…طھط­ط±ظƒ
  Widget _buildFixedHeader(SettingsProvider settings) {
    if (!settings.isVerticalContinuousMode) return const SizedBox.shrink();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: settings.backgroundColor.withOpacity(0.9),
        child: MushafPageWidget(
          page: _pages![_currentPage - 1],
          showInfo: true,
          mushafId: context.read<MushafMetadataProvider>().currentMushafId,
          // ظ†ط­ظ† ظ†ط­طھط§ط¬ ظپظ‚ط· ظ„ظ„ط´ط±ظٹط· ط§ظ„ط¹ظ„ظˆظٹ ظ…ظ† ظ‡ط°ط§ ط§ظ„ظ€ WidgetطŒ ظ„ط°ط§ ط³ظ†ط¬ط¹ظ„ ط§ظ„ظ…ط­طھظˆظ‰ ظپط§ط±ط؛ط§ظ‹ ط£ظˆ ظ†ظ…ط±ط± طھط¹ظ„ظٹظ…ط§طھ ط¨ط°ظ„ظƒ
          // ظ„ظƒظ† ط§ظ„ط£ط¨ط³ط· ظپظٹ ط§ظ„ظˆظ‚طھ ط§ظ„ط­ط§ظ„ظٹ ظ‡ظˆ ط§ط³طھط®ط±ط§ط¬ ط§ظ„ظ€ Header ظپظ‚ط· ط¥ط°ط§ ظ„ط²ظ… ط§ظ„ط£ظ…ط± ظ…ط³طھظ‚ط¨ظ„ط§ظ‹
        ),
      ),
    );
  }

  // --- نظام Auto Scroll المحسّن ---
  void _toggleAutoScroll(SettingsProvider settings) {
    if (_isAutoScrolling) {
      // إذا كان يعمل: إيقاف تام مع العودة للوضع الأفقي
      _exitAutoScrollMode();
    } else {
      // تفعيل الوضع المتحرك
      if (!settings.isVerticalContinuousMode) {
        settings.setNavigationMode(2); // 2 = Vertical Continuous
      }
      _isAutoScrollPaused = false;
      _startAutoScroll();
    }
  }

  /// ضغطة واحدة: إيقاف مؤقت أو استئناف
  void _pauseOrResumeAutoScroll() {
    if (!_isAutoScrolling && !_isAutoScrollPaused) return;
    if (_isAutoScrollPaused) {
      // استئناف
      setState(() => _isAutoScrollPaused = false);
      _autoScrollTimer?.cancel();
      _startAutoScrollTimer();
    } else {
      // إيقاف مؤقت
      setState(() => _isAutoScrollPaused = true);
      _autoScrollTimer?.cancel();
    }
  }

  /// ضغطتان: خروج كامل من الوضع المتحرك مع توقف سلس
  void _exitAutoScrollMode() {
    _autoScrollTimer?.cancel();
    final pageToRestore = _currentPage;

    if (mounted) {
      setState(() {
        _isAutoScrolling = false;
        _isAutoScrollPaused = false;
      });
    }

    final settings = context.read<SettingsProvider>();
    settings.setNavigationMode(0); // العودة للوضع الأفقي

    // انتظار إعادة بناء PageView ثم الانتقال السلس للصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        // قفز فوري لأقرب صفحة ثم animate للسلاسة
        _pageController.jumpToPage(pageToRestore - 1);
      }
    });
  }

  void _startAutoScroll() {
    if (!mounted) return;
    _autoScrollStartTime = DateTime.now(); // بدء العداد للتسارع التدريجي
    setState(() {
      _isAutoScrolling = true;
      _isAutoScrollPaused = false;
    });
    _startAutoScrollTimer();
  }

  /// حساب السرعة الحالية: تسارع ناعم في البداية (easeInOut) وتباطؤ سلس قرب نهاية المحتوى
  double _getCurrentAutoScrollSpeed({double? fractionRemaining}) {
    if (_autoScrollStartTime == null) return _autoScrollMaxSpeed;
    final elapsed = DateTime.now().difference(_autoScrollStartTime!);
    final progress = (elapsed.inMilliseconds / _autoScrollRampDuration.inMilliseconds).clamp(0.0, 1.0);
    // منحنى easeInOut: انطلاق ناعم تدريجياً بدون قفزة سرعة مفاجئة
    final easedProgress = progress < 0.5
        ? 2 * progress * progress
        : 1 - ((2 - 2 * progress) * (2 - 2 * progress) * 0.5);
    final base = _autoScrollMaxSpeed * 0.15 + (_autoScrollMaxSpeed * 0.85 * easedProgress);

    // تباطؤ سلس قرب نهاية المحتوى (smoothstep): نخفض السرعة تدريجياً إلى الصفر
    if (fractionRemaining != null && fractionRemaining < _autoScrollSlowdownStart) {
      final slowProgress = (fractionRemaining / _autoScrollSlowdownStart).clamp(0.0, 1.0);
      final easedSlow = slowProgress * slowProgress * (3 - 2 * slowProgress); // smoothstep
      return base * easedSlow;
    }

    return base;
  }

  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isAutoScrollPaused) return; // إيقاف مؤقت - لا تتحرك
      
      final settings = context.read<SettingsProvider>();
      final currentController = _innerScrollControllers[_currentPage];
      
      // الوضع الهجين: نتمرر داخل الصفحة أولاً
      if (settings.isHybridMode && currentController != null && currentController.hasClients) {
        final maxScroll = currentController.position.maxScrollExtent;
        final currentScroll = currentController.offset;
        
        if (currentScroll < maxScroll) {
          final speed = _getCurrentAutoScrollSpeed();
          // تمرير بكسلي مباشر داخل الصفحة (60fps = سلس طبيعياً)
          currentController.jumpTo(
            (currentScroll + speed).clamp(0.0, maxScroll),
          );
          return;
        }
      }
      
      // التمرير البكسلي في الوضع المستمر
      if (_pageController.hasClients) {
        if (settings.isVerticalContinuousMode) {
          final maxScroll = _pageController.position.maxScrollExtent;
          final current = _pageController.offset;
          if (current < maxScroll) {
            // تباطؤ سلس قرب نهاية المحتوى (آخر 15%) بدلاً من توقف مفاجئ
            final remaining = (maxScroll - current).clamp(0.0, maxScroll);
            final fraction = maxScroll > 0 ? remaining / maxScroll : 1.0;
            final speed = _getCurrentAutoScrollSpeed(fractionRemaining: fraction);
            // jumpTo بكسل واحد لكل إطار = حركة سلسة بدون تداخل animations
            _pageController.jumpTo(
              (current + speed).clamp(0.0, maxScroll),
            );
          } else {
            _stopAutoScroll();
          }
        } else {
          final maxPage = (_pages?.length ?? 604) - 1;
          final currentPageIndex = _pageController.page?.round() ?? _currentPage - 1;
          if (currentPageIndex < maxPage) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else {
            _stopAutoScroll();
          }
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    if (mounted && (_isAutoScrolling || _isAutoScrollPaused)) {
      setState(() {
        _isAutoScrolling = false;
        _isAutoScrollPaused = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      if (_audioListenerAdded) {
        context.read<AudioProvider>().removeListener(_onAudioStateChange);
        _audioListenerAdded = false;
      }
      if (_recitationListenerAdded) {
        context.read<RecitationProvider>().removeListener(_onRecitationStateChange);
        _recitationListenerAdded = false;
      }
      _syncDebounce?.cancel();
      _autoScrollTimer?.cancel();
      _pageController.removeListener(_onScroll);
      _pageController.dispose();
      _secondaryAnimController.dispose();
      // Dispose all inner scroll controllers
      for (var controller in _innerScrollControllers.values) {
        controller.dispose();
      }
    } catch (_) {}
    
    WakelockPlus.disable();
    super.dispose();
  }

  // --- ظ…ظ†ط·ظ‚ ط§ظ„طھظ†ظ‚ظ„ ط«ظ†ط§ط¦ظٹ ط§ظ„ط£ط¨ط¹ط§ط¯ (Bi-directional Navigation) ---

  void _handleSecondaryDragUpdate(DragUpdateDetails details, SettingsProvider settings) {
    if (_isAutoScrolling || settings.isVerticalContinuousMode || settings.isHybridMode) return;
    
    final isHorizontal = settings.isHorizontalMode;
    double delta = isHorizontal ? details.delta.dy : details.delta.dx;
    
    // منع التأثير إذا كان السحب صغيراً جداً في البداية لتجنب الاهتزاز
    if (!_isSecondaryDragging && delta.abs() < 1) return;

    if (!_isSecondaryDragging) {
      final uiProvider = context.read<UiProvider>();
      setState(() {
        _isSecondaryDragging = true;
        _cachedCurrentPageWidget = _buildPageItem(context, _currentPage - 1, settings, uiProvider);
      });
      _secondaryOffsetNotifier.value = 0.0;
    }

    final newOffset = _secondaryOffsetNotifier.value + delta;
    _secondaryOffsetNotifier.value = newOffset;
    
    // تحديد الصفحة المستهدفة (دائماً صفحة واحدة فقط بعيداً عن الحالية)
    int? newTargetPage;
    if (newOffset < 0) {
      newTargetPage = _currentPage + 1;
    } else if (newOffset > 0) {
      newTargetPage = _currentPage - 1;
    }
    
    // التاكد من حدود الصفحات
    final maxPages = _pages?.length ?? 604;
    if (newTargetPage != null) {
      if (newTargetPage < 1) newTargetPage = 1;
      if (newTargetPage > maxPages) newTargetPage = maxPages;
      if (newTargetPage == _currentPage) newTargetPage = null;
    }

    if (_secondaryTargetPage != newTargetPage) {
      final uiProvider = context.read<UiProvider>();
      setState(() {
        _secondaryTargetPage = newTargetPage;
        if (_secondaryTargetPage != null) {
          _cachedTargetPageWidget = _buildPageItem(context, _secondaryTargetPage! - 1, settings, uiProvider);
        } else {
          _cachedTargetPageWidget = null;
        }
      });
    }
  }

  void _handleSecondaryDragEnd(DragEndDetails details, SettingsProvider settings) {
    if (!_isSecondaryDragging) return;
    
    final isHorizontal = settings.isHorizontalMode;
    final screenDimension = isHorizontal 
        ? MediaQuery.of(context).size.height 
        : MediaQuery.of(context).size.width;
        
    // عتبة 12% + قذف أخف — تقليب أسهل بسحبة أصغر دون سحب كبير
    final threshold = screenDimension * 0.12; 
    final velocity = isHorizontal 
        ? details.velocity.pixelsPerSecond.dy 
        : details.velocity.pixelsPerSecond.dx;
    
    final currentOffset = _secondaryOffsetNotifier.value;

    bool shouldFlip = _secondaryTargetPage != null && (
      currentOffset.abs() > threshold || velocity.abs() > 550
    );
    
    if (shouldFlip) {
      double target = currentOffset > 0 ? screenDimension : -screenDimension;
      _animateSecondaryTo(target).then((_) {
        if (mounted) {
          _pageController.jumpToPage(_secondaryTargetPage! - 1);
          setState(() {
            _isSecondaryDragging = false;
            _secondaryOffsetNotifier.value = 0;
            _secondaryTargetPage = null;
            _cachedCurrentPageWidget = null;
            _cachedTargetPageWidget = null;
          });
        }
      });
    } else {
      _animateSecondaryTo(0).then((_) {
        if (mounted) {
          setState(() {
            _isSecondaryDragging = false;
            _secondaryOffsetNotifier.value = 0;
            _secondaryTargetPage = null;
            _cachedCurrentPageWidget = null;
            _cachedTargetPageWidget = null;
          });
        }
      });
    }
  }

  Future<void> _animateSecondaryTo(double target) async {
    // إيقاف أي animation سابق لمنع التداخل
    _secondaryAnimController.stop();
    _secondaryAnimController.reset();

    final currentOffset = _secondaryOffsetNotifier.value;

    final animation = Tween<double>(
      begin: currentOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimController,
      curve: Curves.easeOutCubic,
    ));

    void listener() {
      if (mounted) {
        _secondaryOffsetNotifier.value = animation.value;
      }
    }

    animation.addListener(listener);
    await _secondaryAnimController.forward(from: 0);
    animation.removeListener(listener);
  }

  Widget _buildSecondaryOverlay(SettingsProvider settings, UiProvider uiProvider) {
    return ValueListenableBuilder<double>(
      valueListenable: _secondaryOffsetNotifier,
      builder: (context, offset, child) {
        if (!_isSecondaryDragging && offset == 0) return const SizedBox.shrink();
        
        final isHorizontal = settings.isHorizontalMode;
        final size = MediaQuery.of(context).size;
        
        // نستعمل الصفحة المُخبأة (Cached) لعدم إعادة البناء مع كل بكسل
        final currentPageWidget = _cachedCurrentPageWidget ?? const SizedBox.shrink();
        final targetPageWidget = _cachedTargetPageWidget;
        
        return Stack(
          children: [
            // خلفية لإخفاء PageView أثناء الحركة
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              color: settings.backgroundColor,
            ),
            
            // الصفحة المستهدفة (تأتي من الخلف أو أمام)
            if (targetPageWidget != null)
              Transform.translate(
                offset: isHorizontal 
                    ? Offset(0, offset > 0 ? offset - size.height : offset + size.height)
                    : Offset(offset > 0 ? offset - size.width : offset + size.width, 0),
                child: targetPageWidget,
              ),
              
            // الصفحة الحالية مع ظل
            Transform.translate(
              offset: isHorizontal ? Offset(0, offset) : Offset(offset, 0),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (offset != 0)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: currentPageWidget,
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final uiProvider = Provider.of<UiProvider>(context);
    
    // Handle Jump Signal
    if (uiProvider.pageToJump != null) {
      final page = uiProvider.pageToJump!;
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

    final mushafMetadata = context.watch<MushafMetadataProvider>();
    
    if (_isLoading) {
      return _buildLoadingScreen(isDark, settings);
    }
    
    if (_errorMessage != null) {
      return _buildErrorScreen(isDark, settings);
    }
    
    if (_pages == null || _pages!.isEmpty) {
      return _buildEmptyScreen(isDark, settings);
    }
    
    int totalPages = 604;
    try {
      final currentId = mushafMetadata.currentMushafId;
      final mushaf = mushafMetadata.availableMushafs.firstWhere((m) => m.identifier == currentId);
      totalPages = mushaf.pageCount;
    } catch (_) {
      totalPages = _pages?.length ?? 604;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: settings.backgroundColor,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                     if (_isAutoScrolling || _isAutoScrollPaused) {
                       // في الوضع المتحرك: ضغطة واحدة = إيقاف مؤقت أو استئناف
                       _pauseOrResumeAutoScroll();
                     } else {
                       // في الأوضاع الأخرى: إخفاء/إظهار الأشرطة
                       Provider.of<UiProvider>(context, listen: false).toggleImmersiveMode();
                       _updateSystemUI();
                     }
                  },
                  onDoubleTap: () {
                    final settings = context.read<SettingsProvider>();
                    if (_isAutoScrolling || _isAutoScrollPaused) {
                      // ضغطتان في الوضع المتحرك: خروج كامل مع توقف سلس
                      _exitAutoScrollMode();
                    } else {
                      // ضغطتان خارج الوضع المتحرك: تفعيله
                      if (!settings.isVerticalContinuousMode) {
                        settings.setNavigationMode(2);
                      }
                      _isAutoScrollPaused = false;
                      _startAutoScroll();
                    }
                  },
                  onVerticalDragUpdate: (details) {
                    if (settings.isHorizontalMode) {
                      _handleSecondaryDragUpdate(details, settings);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (settings.isHorizontalMode) {
                      _handleSecondaryDragEnd(details, settings);
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (!settings.isHorizontalMode) {
                      _handleSecondaryDragUpdate(details, settings);
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (!settings.isHorizontalMode) {
                      _handleSecondaryDragEnd(details, settings);
                    }
                  },
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return PageView.builder(
                          key: ValueKey('${settings.navigationMode}_${settings.pageDragSensitivity}'),
                          physics: _getScrollPhysics(settings),
                          scrollDirection: settings.isHorizontalMode || settings.isHybridMode
                              ? Axis.horizontal 
                              : Axis.vertical,
                          pageSnapping: !settings.isVerticalContinuousMode,
                          controller: _pageController,
                          itemCount: totalPages,
                          reverse: false,
                          onPageChanged: (index) {
                            final page = index + 1;
                            setState(() {
                              _currentPage = page;
                            });
                            _syncPageWithProvider(page);
                            // ط­ظپط¸ ط¢ط®ط± طµظپط­ط© ظ‚ط±ط§ط،ط©
                            context.read<SettingsProvider>().setLastPage(page);
                          },
                          itemBuilder: (context, index) {
                            return _buildPageItem(context, index, settings, uiProvider);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // AudioMinibar removed â€” it's already in main_shell_screen
          
          // Auto Scroll Indicator
          if (_isAutoScrolling || _isAutoScrollPaused)
            Positioned(
              top: 100,
              right: 16,
              left: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAutoScrollPaused ? Colors.orange.shade800.withAlpha(220) : Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الإيقاف المؤقت / الاستئناف
                      InkWell(
                        onTap: _pauseOrResumeAutoScroll,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isAutoScrollPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // النص
                      Text(
                        _isAutoScrollPaused ? AppLocalizations.of(context)!.autoScrollPaused : AppLocalizations.of(context)!.autoScrollActive,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // زر الإيقاف النهائي
                      InkWell(
                        onTap: _exitAutoScrollMode,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // ط§ظ„ط´ط±ظٹط· ط§ظ„ط¹ظ„ظˆظٹ ط§ظ„ط«ط§ط¨طھ (ظٹط¸ظ‡ط± ظپظ‚ط· ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ…طھط­ط±ظƒ)
          if (settings.isVerticalContinuousMode) 
            Positioned(
              top: 0, left: 0, right: 0,
              height: ResponsiveConstants.getTopBarHeight(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                color: settings.backgroundColor,
                child: MushafPageWidget(
                  page: _pages![_currentPage - 1],
                  mushafId: context.read<MushafMetadataProvider>().currentMushafId,
                  showInfo: true,
                  hideContent: true, // ط¥ط®ظپط§ط، ظ…ط­طھظˆظ‰ ط§ظ„طµظپط­ط© ظˆط§ظ„ط§ظƒطھظپط§ط، ط¨ط§ظ„ط´ط±ظٹط· ط§ظ„ط¹ظ„ظˆظٹ
                ),
              ),
            ),

          // Secondary Drag Overlay (ط§ظ„طھظ†ظ‚ظ„ ط«ظ†ط§ط¦ظٹ ط§ظ„ط£ط¨ط¹ط§ط¯ - ظٹط¹ظ…ظ„ ظپظ‚ط· ظپظٹ ظˆط¶ط¹ ط§ظ„طµظپط­ط§طھ)
          if (!settings.isVerticalContinuousMode)
            _buildSecondaryOverlay(settings, uiProvider),
        ],
      ),
    );
  }
  
  ScrollPhysics _getScrollPhysics(SettingsProvider settings) {
    if (settings.isVerticalContinuousMode) {
      return const ClampingScrollPhysics();
    }
    
    return SensitivePageScrollPhysics(
      dragThreshold: settings.pageDragSensitivity,
      flingVelocity: settings.minFlingVelocity,
    );
  }
  
  Widget _buildPageItem(BuildContext context, int index, SettingsProvider settings, UiProvider uiProvider) {
    final currentType = context.read<MushafMetadataProvider>().currentMushafType;
    final currentId = context.read<MushafMetadataProvider>().currentMushafId;
    final isDigital = currentType == 'digital';
    
    // ط¥ظ†ط´ط§ط، ScrollController ظ„ظ„طµظپط­ط© ط¥ط°ط§ ظ„ظ… ظٹظƒظ† ظ…ظˆط¬ظˆط¯ط§ظ‹ (ظ„ظ„ظˆط¶ط¹ ط§ظ„ظ‡ط¬ظٹظ†)
    if (settings.isHybridMode && !_innerScrollControllers.containsKey(index + 1)) {
      _innerScrollControllers[index + 1] = ScrollController();
    }
    
    Widget pageContent;
    
    if (currentType == 'image') {
      final mushafProvider = context.read<MushafMetadataProvider>();
      final mushaf = mushafProvider.availableMushafs.firstWhere(
        (m) => m.identifier == currentId,
        orElse: () => mushafProvider.availableMushafs.first
      );
      
      pageContent = MushafImageWidget(
        pageNumber: _pages![index].page,
        mushafId: currentId,
        baseUrl: mushaf.baseUrl ?? '',
        imageExtension: mushaf.imageExtension ?? 'jpg',
      );
    } else {
      pageContent = MushafPageWidget(
        page: _pages![index],
        mushafId: currentId,
        selectedSurah: _selectedSurah,
        selectedAyah: _selectedAyah,
        // إيقاف الضغط على الآيات في الوضع المتحرك لمنع التعارض مع ضغطة الإيقاف
        onAyahSelected: (_isAutoScrolling || _isAutoScrollPaused) ? null : _onAyahInteraction,
        onAyahLongPress: (_isAutoScrolling || _isAutoScrollPaused) ? null : _onAyahInteraction,
        showInfo: !settings.isVerticalContinuousMode,
        isDigital: isDigital,
      );
    }
    
    // ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ‡ط¬ظٹظ†طŒ ظ†ط¶ظٹظپ SingleChildScrollView ط¯ط§ط®ظ„ظٹ
    if (settings.isHybridMode) {
      pageContent = SingleChildScrollView(
        controller: _innerScrollControllers[index + 1],
        physics: const ClampingScrollPhysics(),
        child: pageContent,
      );
    }
    
    // لا نلف بـ GestureDetector هنا — كل النقرات تُعالج من الخارج (سطر 718)
    return pageContent;
  }
  
  Widget _buildLoadingScreen(bool isDark, SettingsProvider settings) {
    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ط§ظ„ظ…طµط­ظپ ط§ظ„ط´ط±ظٹظپ',
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
              'ط¬ط§ط±ظٹ طھط­ظ…ظٹظ„ ط§ظ„ظ…طµط­ظپ...',
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
  
  Widget _buildErrorScreen(bool isDark, SettingsProvider settings) {
    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ط§ظ„ظ…طµط­ظپ ط§ظ„ط´ط±ظٹظپ',
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
              onPressed: () {
                if (_errorMessage!.contains('تحميل')) {
                  // Navigate to settings
                  context.read<UiProvider>().setTabIndex(3); // settings is index 3
                } else {
                  _loadPages();
                }
              },
              icon: Icon(_errorMessage!.contains('تحميل') ? Icons.download_rounded : Icons.refresh),
              label: Text(_errorMessage!.contains('تحميل') ? 'الانتقال للتحميل' : 'إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: _errorMessage!.contains('تحميل') ? AppColors.primary : null,
                foregroundColor: _errorMessage!.contains('تحميل') ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyScreen(bool isDark, SettingsProvider settings) {
    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ط§ظ„ظ…طµط­ظپ ط§ظ„ط´ط±ظٹظپ',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'ظ„ط§ طھظˆط¬ط¯ ط¨ظٹط§ظ†ط§طھ',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
  
  // Debounce timer (reserved for future use, cancelled in dispose)
  Timer? _syncDebounce;
  int? _pendingContinuousPage; // أحدث صفحة مستهدفة تنتظر مزامنتها في الوضع المستمر
  bool _audioListenerAdded = false; // guard against duplicate listeners
  bool _recitationListenerAdded = false; // guard against duplicate listeners

  /// مزامنة رقم الصفحة في الوضع المستمر بتردد محدود (مرة كل 66ms) لضمان سلاسة الحركة
  /// دون إعادة بناء كاملة للشاشة مع كل بكسل تمرير.
  void _debouncedContinuousPageSync(int page) {
    // نحتفظ بأحدث صفحة فقط (تجاهل القيم الوسيطة أثناء التمرير السريع)
    _pendingContinuousPage = page;
    if (_syncDebounce != null) return; // يوجد جدول زمني قائم بالفعل

    _syncDebounce = Timer(const Duration(milliseconds: 66), () {
      _syncDebounce = null;
      if (!mounted) return;
      final target = _pendingContinuousPage;
      _pendingContinuousPage = null;
      if (target == null || target == _currentPage) return;
      setState(() {
        _currentPage = target;
      });
      _syncPageWithProvider(target);
    });
  }

  void _syncPageWithProvider(int pageNum) {
    final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
    
    // Update current page in UiProvider immediately
    context.read<UiProvider>().setCurrentMushafPage(pageNum);
    
    if (mushafId == 'shamarly_15lines') {
       // Shamarly: uses its own JSON page data
       final navProvider = context.read<MushafNavigationProvider>();
       final pageInfo = navProvider.getPageInfo(pageNum);
       if (pageInfo != null && pageInfo.startSurah > 0) {
         final surah = pageInfo.startSurah;
         final ayah = pageInfo.startAyah > 0 ? pageInfo.startAyah : 1;
         context.read<QuranProvider>().updateReadingLocation(surah, ayah);
         context.read<AudioProvider>().setContext(surah, ayah);
         
         // Async improvement from DB (fire and forget)
         context.read<QuranProvider>().getAyah(surah, ayah).then((either) {
           either.fold(
             (failure) => null,
             (ayahObj) {
               if (ayahObj != null && mounted) {
                 context.read<QuranProvider>().updateReadingLocation(ayahObj.surahNumber, ayahObj.ayahNumber);
                 context.read<AudioProvider>().setContext(ayahObj.surahNumber, ayahObj.ayahNumber);
               }
             }
           );
         });
       }
    } else {
       // Madani (v1/v2): use full 604-page static map — instant, no DB needed
       final surah = MushafNavigationProvider.surahForPageFull(pageNum);
       final ayah  = MushafNavigationProvider.ayahForPageFull(pageNum);
       context.read<QuranProvider>().updateReadingLocation(surah, ayah);
       context.read<AudioProvider>().setContext(surah, ayah);
    }
  }
}
