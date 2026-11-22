import 'package:material_ui/material_ui.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/presentation/widgets/mushaf_image_widget.dart';
import 'package:mathani/presentation/widgets/digital_khatt_mushaf_page_widget.dart';

import '../../../data/services/digital_khatt_page_loader.dart';

import 'package:mathani/presentation/widgets/reader_page_frame.dart';
import 'package:mathani/presentation/widgets/reader_loading_indicator.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/widgets/dialogs/ayah_content_sheet.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/mushaf_metadata_provider.dart';
import '../../../data/providers/mushaf_navigation_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/recitation_provider.dart';
import '../../providers/settings_provider.dart';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/utils/reader_swipe_policy.dart';
import '../../../core/services/reader_system_ui.dart';

import 'dart:async';

class MushafScreen extends StatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

/// ScrollPhysics ظ…ط®طµطµ ظ„ط¶ظ…ط§ظ† ط§ظ„طھظ†ظ‚ظ„ ط¨ظٹظ† ط§ظ„طµظپط­ط§طھ ط¨ط¯ظ‚ط© (طµظپط­ط© ظˆط§ط­ط¯ط© ظ„ظƒظ„ طھظ…ط±ظٹط±ط©)
class SensitivePageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;
  final double flingVelocity;

  const SensitivePageScrollPhysics({
    super.parent,
    this.dragThreshold =
        10.0, // عتبة سحب منخفضة — يتبع الإصبع مبكراً وتقليب أسهل بسحبة أصغر
    this.flingVelocity = 90.0, // قذف أسهل — لمسة/سحبة خفيفة تكفي للانتقال
  });

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

class _MushafScreenState extends State<MushafScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _readerActive = false;
  bool _routeVisible = true;
  late UiProvider _visibilityUi;
  bool _foreground = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncReaderActivity();
  }

  void _syncReaderActivity() {
    final active =
        _foreground &&
        _routeVisible &&
        _visibilityUi.currentTabIndex == 1 &&
        !_visibilityUi.showingTafsir;
    if (active == _readerActive) return;
    _readerActive = active;
    _setReaderWakelock(active);
    if (!active) {
      _autoScrollTimer?.cancel();
    } else if (_isAutoScrolling && !_isAutoScrollPaused) {
      _autoScrollStartTime = DateTime.now();
      _startAutoScrollTimer();
    }
  }

  Future<void> _setReaderWakelock(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (e) {
      debugPrint('Reader wake lock: $e');
    }
  }

  final GlyphDataLoader _loader = GlyphDataLoader();
  List<PageGlyph>? _pages;
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;
  int _currentPage = 1;
  int? _recitationPageTarget;
  String? _loadedMushafId;
  String? _displayMushafId;
  String? _displayMushafType;
  int _pageLoadGeneration = 0;
  int? _lastNavigationMode;

  // Auto Scroll State
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  bool _isAutoScrollPaused = false; // للإيقاف المؤقت بضغطة واحدة
  static const double _autoScrollMaxSpeed =
      0.22; // ~13 بكسل/ث — صفحة (~800-900px) تُنجز في ~دقيقة
  static const Duration _autoScrollInterval = Duration(
    milliseconds: 16,
  ); // ~60fps
  static const Duration _autoScrollRampDuration = Duration(
    seconds: 5,
  ); // تسارع أطول وناعم (بدون قفزة)
  static const double _autoScrollSlowdownStart =
      0.15; // بدء التباطؤ السلس في آخر 15% من المحتوى
  DateTime? _autoScrollStartTime; // وقت بدء التمرير

  // ScrollControllers ظ„ظ„طµظپط­ط§طھ ط§ظ„ظپط±ط¯ظٹط© (ظ„ظ„ظˆط¶ط¹ Hybrid)
  final Map<int, ScrollController> _innerScrollControllers = {};

  // Bi-directional Drag State (للتنقل ثنائي الأبعاد)
  final ValueNotifier<double> _secondaryOffsetNotifier = ValueNotifier(0.0);
  bool _isSecondaryDragging = false;
  bool _secondarySettling = false;
  int _secondaryGestureId = 0;
  Size _readerSize = Size.zero;
  bool? _appliedImmersiveMode;
  bool? _appliedDarkMode;
  int? _secondaryTargetPage;
  // Cache pages for smooth dragging without rebuilds
  Widget? _cachedTargetPageWidget;
  final Map<String, GlobalKey> _verticalPageKeys = {};
  late AnimationController _secondaryAnimController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
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

    _visibilityUi = context.read<UiProvider>()
      ..addListener(_syncReaderActivity);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_audioListenerAdded) {
        context.read<AudioProvider>().addListener(_onAudioStateChange);
        _audioListenerAdded = true;
      }
      if (!_recitationListenerAdded) {
        context.read<RecitationProvider>().addListener(
          _onRecitationStateChange,
        );
        _recitationListenerAdded = true;
      }
    });
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
            curve: Curves.easeInOut,
          );
        }
      }

      if (_selectedSurah != audio.currentSurah ||
          _selectedAyah != audio.currentAyah) {
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
          page = navProvider.getPageForAyah(
            recitation.matchedSurah!,
            recitation.matchedAyah!,
          );
        } else {
          page = MushafNavigationProvider.pageForSurahAyah(
            recitation.matchedSurah!,
            recitation.matchedAyah!,
          );
        }

        if (page != null &&
            page != _currentPage &&
            page != _recitationPageTarget &&
            _pageController.hasClients) {
          _recitationPageTarget = page;
          unawaited(
            _pageController
                .animateToPage(
                  page - 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                )
                .whenComplete(() {
                  if (_recitationPageTarget == page) {
                    _recitationPageTarget = null;
                  }
                }),
          );
        }

        _selectedSurah = recitation.matchedSurah;
        _selectedAyah = recitation.matchedAyah;
      }
      setState(() {});
    } else {
      _recitationPageTarget = null;
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
        final topOffset = _pageController.offset;
        final topPage = (topOffset / viewportHeight).floor() + 1;
        if (topPage != _currentPage &&
            topPage >= 1 &&
            topPage <= (_pages?.length ?? 604)) {
          // دمج المزامنة بتردد محدود لتجنّب إعادة بناء الشاشة مع كل بكسل (سلاسة الوضع المستمر)
          _debouncedContinuousPageSync(topPage);
        }
      }
    }
  }

  Future<void> _loadPages() async {
    final generation = ++_pageLoadGeneration;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mushafProvider = context.read<MushafMetadataProvider>();
      final currentType = mushafProvider.currentMushafType;
      final currentId = mushafProvider.currentMushafId;

      final navProvider = Provider.of<MushafNavigationProvider>(
        context,
        listen: false,
      );
      int pageCount = navProvider.totalPages;
      try {
        final mushaf = mushafProvider.availableMushafs.firstWhere(
          (m) => m.identifier == currentId,
        );
        pageCount = mushaf.pageCount;
      } catch (_) {}

      List<PageGlyph> pages;

      if (currentType != 'font_v2') {
        pages = List.generate(
          pageCount,
          (index) => PageGlyph(page: index + 1, lines: []),
        );
      } else {
        pages = await _loader.loadAllPages();
      }

      if (pages.isEmpty) {
        throw StateError('لا توجد صفحات متاحة في المصحف المختار');
      }
      if (mounted && generation == _pageLoadGeneration) {
        setState(() {
          _pages = pages;
          _displayMushafId = currentId;
          _displayMushafType = currentType;
          _currentPage = _currentPage.clamp(1, pages.length);
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              generation != _pageLoadGeneration ||
              !_pageController.hasClients) {
            return;
          }
          _pageController.jumpToPage(_currentPage - 1);
        });
      }
    } catch (e) {
      if (mounted && generation == _pageLoadGeneration) {
        setState(() {
          _errorMessage = 'تعذّر تحميل المصحف: $e';
          _isLoading = false;
        });
      }
    }
  }

  int? _selectedSurah;
  int? _selectedAyah;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = ModalRoute.of(context)?.isCurrent ?? true;
    _syncReaderActivity();
    final navigationMode = context.read<SettingsProvider>().navigationMode;
    if (_lastNavigationMode != null && _lastNavigationMode != navigationMode) {
      _resetSecondaryDrag();
    }
    _lastNavigationMode = navigationMode;
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

    if (_appliedImmersiveMode != uiProvider.isImmersiveMode) {
      _appliedImmersiveMode = uiProvider.isImmersiveMode;
      ReaderSystemUi.setImmersiveMode(uiProvider.isImmersiveMode)
          .catchError((Object error) {
            _appliedImmersiveMode = null;
            debugPrint('Unable to update reader system bars: $error');
            return false;
          });
    }
    if (_appliedDarkMode != isDark) {
      _appliedDarkMode = isDark;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
      );
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
      builder: (context) =>
          AyahContentSheet(surahNumber: surah, ayaNumber: ayah, wordCount: 100),
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
  // --- نظام Auto Scroll المحسّن ---
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
    final progress =
        (elapsed.inMilliseconds / _autoScrollRampDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );
    // منحنى easeInOut: انطلاق ناعم تدريجياً بدون قفزة سرعة مفاجئة
    final easedProgress = progress < 0.5
        ? 2 * progress * progress
        : 1 - ((2 - 2 * progress) * (2 - 2 * progress) * 0.5);
    final base =
        _autoScrollMaxSpeed * 0.15 +
        (_autoScrollMaxSpeed * 0.85 * easedProgress);

    // تباطؤ سلس قرب نهاية المحتوى (smoothstep): نخفض السرعة تدريجياً إلى الصفر
    if (fractionRemaining != null &&
        fractionRemaining < _autoScrollSlowdownStart) {
      final slowProgress = (fractionRemaining / _autoScrollSlowdownStart).clamp(
        0.0,
        1.0,
      );
      final easedSlow =
          slowProgress * slowProgress * (3 - 2 * slowProgress); // smoothstep
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

      final ui = context.read<UiProvider>();
      if (ui.currentTabIndex != 1 || ui.showingTafsir) {
        return; // لا تمرر إذا كان القارئ غير ظاهر في الواجهة
      }

      final settings = context.read<SettingsProvider>();
      final currentController = _innerScrollControllers[_currentPage];

      // الوضع الهجين: نتمرر داخل الصفحة أولاً
      if (settings.isHybridMode &&
          currentController != null &&
          currentController.hasClients) {
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
            final speed = _getCurrentAutoScrollSpeed(
              fractionRemaining: fraction,
            );
            // jumpTo بكسل واحد لكل إطار = حركة سلسة بدون تداخل animations
            _pageController.jumpTo((current + speed).clamp(0.0, maxScroll));
          } else {
            _stopAutoScroll();
          }
        } else {
          final maxPage = (_pages?.length ?? 604) - 1;
          final currentPageIndex =
              _pageController.page?.round() ?? _currentPage - 1;
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
    _secondaryGestureId++;
    _pageLoadGeneration++;
    try {
      if (_audioListenerAdded) {
        context.read<AudioProvider>().removeListener(_onAudioStateChange);
        _audioListenerAdded = false;
      }
      if (_recitationListenerAdded) {
        context.read<RecitationProvider>().removeListener(
          _onRecitationStateChange,
        );
        _recitationListenerAdded = false;
      }
    } catch (_) {}
    _syncDebounce?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _secondaryAnimController.dispose();
    _secondaryOffsetNotifier.dispose();
    // Dispose all inner scroll controllers
    for (var controller in _innerScrollControllers.values) {
      controller.dispose();
    }
    _visibilityUi.removeListener(_syncReaderActivity);
    WidgetsBinding.instance.removeObserver(this);
    if (_readerActive) _setReaderWakelock(false);
    super.dispose();
  }

  // --- ظ…ظ†ط·ظ‚ ط§ظ„طھظ†ظ‚ظ„ ط«ظ†ط§ط¦ظٹ ط§ظ„ط£ط¨ط¹ط§ط¯ (Bi-directional Navigation) ---

  void _resetSecondaryDrag() {
    _secondaryGestureId++;
    _secondaryAnimController.stop();
    _secondarySettling = false;
    if (!mounted) return;
    setState(() {
      _isSecondaryDragging = false;
      _secondaryOffsetNotifier.value = 0;
      _secondaryTargetPage = null;
      _cachedTargetPageWidget = null;
    });
  }

  void _handleSecondaryDragUpdate(
    DragUpdateDetails details,
    SettingsProvider settings,
  ) {
    if (_secondarySettling ||
        _isAutoScrolling ||
        settings.isVerticalContinuousMode ||
        settings.isHybridMode) {
      return;
    }
    if (!_isSecondaryDragging &&
        _pageController.hasClients &&
        _pageController.position.isScrollingNotifier.value) {
      return;
    }
    final horizontal = settings.isHorizontalMode;
    final delta = horizontal ? details.delta.dy : details.delta.dx;
    if (!_isSecondaryDragging) {
      setState(() {
        _isSecondaryDragging = true;
      });
      _secondaryOffsetNotifier.value = 0;
    }
    final extent = horizontal ? _readerSize.height : _readerSize.width;
    final offset = (_secondaryOffsetNotifier.value + delta)
        .clamp(-extent, extent)
        .toDouble();
    final target = ReaderSwipePolicy.targetPage(
      page: _currentPage,
      pageCount: _pages?.length ?? 604,
      offset: offset,
      primaryAxis: horizontal ? Axis.horizontal : Axis.vertical,
    );
    _secondaryOffsetNotifier.value = target == null ? offset * .18 : offset;
    if (_secondaryTargetPage != target) {
      final ui = context.read<UiProvider>();
      setState(() {
        _secondaryTargetPage = target;
        _cachedTargetPageWidget = target == null
            ? null
            : _buildPageItem(target - 1, settings, ui);
      });
    }
  }

  void _handleSecondaryDragEnd(
    DragEndDetails details,
    SettingsProvider settings,
  ) {
    if (!_isSecondaryDragging || _secondarySettling) return;
    final horizontal = settings.isHorizontalMode;
    final extent = horizontal ? _readerSize.height : _readerSize.width;
    final velocity = horizontal
        ? details.velocity.pixelsPerSecond.dy
        : details.velocity.pixelsPerSecond.dx;
    final offset = _secondaryOffsetNotifier.value;
    final targetPage = _secondaryTargetPage;
    final commit =
        targetPage != null &&
        ReaderSwipePolicy.shouldCommit(
          offset: offset,
          velocity: velocity,
          extent: extent,
        );
    final gesture = ++_secondaryGestureId;
    _secondarySettling = true;
    _animateSecondaryTo(commit ? (offset > 0 ? extent : -extent) : 0)
        .then((completed) {
          if (!mounted || !completed || gesture != _secondaryGestureId) return;
          if (commit && _pageController.hasClients) {
            _pageController.jumpToPage(targetPage - 1);
          }
          _resetSecondaryDrag();
        });
  }

  Future<bool> _animateSecondaryTo(double target) async {
    _secondaryAnimController.stop();
    _secondaryAnimController.reset();
    final animation =
        Tween<double>(
          begin: _secondaryOffsetNotifier.value,
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _secondaryAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    void listener() {
      if (mounted) _secondaryOffsetNotifier.value = animation.value;
    }

    animation.addListener(listener);
    try {
      await _secondaryAnimController.forward(from: 0).orCancel;
      return true;
    } on TickerCanceled {
      return false;
    } finally {
      animation.removeListener(listener);
    }
  }

  Widget _buildSecondaryOverlay(
    SettingsProvider settings,
    UiProvider uiProvider,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: _secondaryOffsetNotifier,
      builder: (context, offset, child) {
        if (!_isSecondaryDragging && offset == 0) {
          return const SizedBox.shrink();
        }

        final isHorizontal = settings.isHorizontalMode;
        final size = _readerSize;

        // نستعمل الصفحة المُخبأة (Cached) لعدم إعادة البناء مع كل بكسل
        final targetPageWidget = _cachedTargetPageWidget;

        return Stack(
          children: [
            // الصفحة المستهدفة (تأتي من الخلف أو أمام)
            if (targetPageWidget != null)
              Transform.translate(
                offset: isHorizontal
                    ? Offset(
                        0,
                        offset > 0
                            ? offset - size.height
                            : offset + size.height,
                      )
                    : Offset(
                        offset > 0 ? offset - size.width : offset + size.width,
                        0,
                      ),
                child: targetPageWidget,
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
      final navProvider = Provider.of<MushafNavigationProvider>(
        context,
        listen: false,
      );
      final maxPages = _pages?.length ?? navProvider.totalPages;
      final targetPage = page.clamp(1, maxPages < 1 ? 1 : maxPages);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || uiProvider.pageToJump != page) return;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetPage - 1);
          uiProvider.consumeJump();
        }
      });
    }

    context.watch<MushafMetadataProvider>();

    if (_isLoading && _pages == null) {
      return _buildLoadingScreen(isDark, settings);
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(isDark, settings);
    }

    if (_pages == null || _pages!.isEmpty) {
      return _buildEmptyScreen(isDark, settings);
    }

    final totalPages = _pages!.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: _pageDecoration(settings),
      child: IgnorePointer(
        ignoring: _isLoading,
        child: ReaderPageFrame(
          immersive: uiProvider.isImmersiveMode,
          child: Column(
            children: [
              SizedBox(
                height: 45,
                child: MushafPageWidget(
                  key: const ValueKey('reader-page-header'),
                  page: _pages![_currentPage - 1],
                  mushafId: _displayMushafId,
                  showInfo: true,
                  hideContent: true,
                  paintBackground: false,
                  headerHeight: 45,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _readerSize = constraints.biggest;
                    return Stack(
                      key: const ValueKey('reader-page-viewport'),
                      children: [
                        if (!settings.isVerticalContinuousMode)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _buildSecondaryOverlay(
                                settings,
                                uiProvider,
                              ),
                            ),
                          ),
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
                                    Provider.of<UiProvider>(
                                      context,
                                      listen: false,
                                    ).toggleImmersiveMode();
                                    _updateSystemUI();
                                  }
                                },
                                onDoubleTap: () {
                                  final settings = context
                                      .read<SettingsProvider>();
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
                                onVerticalDragUpdate: settings.isHorizontalMode
                                    ? (details) => _handleSecondaryDragUpdate(
                                        details,
                                        settings,
                                      )
                                    : null,
                                onVerticalDragEnd: settings.isHorizontalMode
                                    ? (details) => _handleSecondaryDragEnd(
                                        details,
                                        settings,
                                      )
                                    : null,
                                onVerticalDragCancel: settings.isHorizontalMode
                                    ? _resetSecondaryDrag
                                    : null,
                                onHorizontalDragUpdate:
                                    settings.isVerticalPagedMode
                                    ? (details) => _handleSecondaryDragUpdate(
                                        details,
                                        settings,
                                      )
                                    : null,
                                onHorizontalDragEnd:
                                    settings.isVerticalPagedMode
                                    ? (details) => _handleSecondaryDragEnd(
                                        details,
                                        settings,
                                      )
                                    : null,
                                onHorizontalDragCancel:
                                    settings.isVerticalPagedMode
                                    ? _resetSecondaryDrag
                                    : null,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _secondaryOffsetNotifier,
                                  builder: (context, offset, child) =>
                                      Transform.translate(
                                        offset: settings.isHorizontalMode
                                            ? Offset(0, offset)
                                            : Offset(offset, 0),
                                        child: child,
                                      ),
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Consumer<SettingsProvider>(
                                      builder: (context, settings, child) {
                                        return PageView.builder(
                                          key: ValueKey(
                                            'reader-pages-$_displayMushafId',
                                          ),
                                          physics:
                                              _isSecondaryDragging ||
                                                  _secondarySettling
                                              ? const NeverScrollableScrollPhysics()
                                              : _getScrollPhysics(settings),
                                          scrollDirection:
                                              settings.isHorizontalMode ||
                                                  settings.isHybridMode
                                              ? Axis.horizontal
                                              : Axis.vertical,
                                          pageSnapping: !settings
                                              .isVerticalContinuousMode,
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
                                            context
                                                .read<SettingsProvider>()
                                                .setLastPage(page);
                                          },
                                          itemBuilder: (context, index) {
                                            // The incoming page is owned by the vertical
                                            // overlay until the transition completes.
                                            if (settings.isHorizontalMode &&
                                                _isSecondaryDragging &&
                                                index + 1 ==
                                                    _secondaryTargetPage) {
                                              return const SizedBox.expand();
                                            }
                                            return _buildPageItem(
                                              index,
                                              settings,
                                              uiProvider,
                                            );
                                          },
                                        );
                                      },
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isAutoScrollPaused
                                      ? Colors.orange.shade800.withAlpha(220)
                                      : Colors.black.withAlpha(160),
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
                                          _isAutoScrollPaused
                                              ? Icons.play_arrow_rounded
                                              : Icons.pause_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // النص
                                    Text(
                                      _isAutoScrollPaused
                                          ? AppLocalizations.of(context)!
                                                .autoScrollPaused
                                          : AppLocalizations.of(context)!
                                                .autoScrollActive,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                      ),
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
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildPageItem(
    int index,
    SettingsProvider settings,
    UiProvider uiProvider,
  ) {
    final currentId = _displayMushafId!;
    final page = _pages![index];

    // ط¥ظ†ط´ط§ط، ScrollController ظ„ظ„طµظپط­ط© ط¥ط°ط§ ظ„ظ… ظٹظƒظ† ظ…ظˆط¬ظˆط¯ط§ظ‹ (ظ„ظ„ظˆط¶ط¹ ط§ظ„ظ‡ط¬ظٹظ†)
    if (settings.isHybridMode &&
        !_innerScrollControllers.containsKey(index + 1)) {
      _innerScrollControllers[index + 1] = ScrollController();
    }

    final currentType = _displayMushafType!;
    Widget pageContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      // Keep the visibility state live even for the cached swipe preview.
      child: Consumer<RecitationProvider>(
        builder: (context, recitation, child) => _buildPageContent(
          context,
          page,
          currentType,
          currentId,
          recitation,
          uiProvider.showRecitationMinibar,
          uiProvider.isRecitationActive,
        ),
      ),
    );

    // Keep the line layout bounded inside the hybrid scrolling viewport.
    if (settings.isHybridMode) {
      pageContent = SingleChildScrollView(
        controller: _innerScrollControllers[index + 1],
        physics: const ClampingScrollPhysics(),
        child: SizedBox(height: _readerSize.height, child: pageContent),
      );
    }

    // لا نلف بـ GestureDetector هنا — كل النقرات تُعالج من الخارج (سطر 718)
    if (settings.isHorizontalMode) {
      final identity = '$currentId-${page.page}';
      return KeyedSubtree(
        key: _verticalPageKeys.putIfAbsent(identity, () => GlobalKey()),
        child: pageContent,
      );
    }
    return pageContent;
  }

  Widget _buildPageContent(
    BuildContext context,
    PageGlyph page,
    String mushafType,
    String mushafId,
    RecitationProvider recitation,
    bool showRecitationMinibar,
    bool isRecitationActive,
  ) {
    final hideVerses =
        showRecitationMinibar &&
        recitation.hideVerses &&
        (recitation.isRecording || recitation.isInitializingRecording);
    final revealedWordKeys = hideVerses ? recitation.revealedWordKeys : null;
    final wordVerdicts = isRecitationActive
        ? recitation.liveWordVerdicts
        : const <String, WordVerdict>{};
    final onAyahLongPress =
        _isAutoScrolling || _isAutoScrollPaused || hideVerses
        ? null
        : _onAyahInteraction;

    if (mushafType == 'single_font') {
      final isOldMadina = mushafId == 'digital_khatt_old_madina';
      return DigitalKhattMushafPageWidget(
        pageNumber: page.page,
        fontFamily: isOldMadina
            ? 'DigitalKhattOldMadina'
            : 'DigitalKhattMadina',
        loader: isOldMadina
            ? digitalKhattOldMadinaLoader
            : digitalKhattPageLoader,
        wordVerdicts: wordVerdicts,
        revealedWordKeys: revealedWordKeys,
        selectedSurah: _selectedSurah,
        selectedAyah: _selectedAyah,
        onAyahLongPress: onAyahLongPress,
      );
    }

    if (mushafType == 'image') {
      final mushafs = context.read<MushafMetadataProvider>().availableMushafs;
      final mushaf = mushafs.firstWhere(
        (entry) => entry.identifier == mushafId,
        orElse: () => mushafs.first,
      );
      return MushafImageWidget(
        pageNumber: page.page,
        mushafId: mushafId,
        baseUrl: mushaf.baseUrl ?? '',
        imageExtension: mushaf.imageExtension ?? 'jpg',
        showInfo: false,
        revealedWordKeys: revealedWordKeys,
      );
    }

    return MushafPageWidget(
      page: page,
      mushafId: mushafId,
      selectedSurah: _selectedSurah,
      selectedAyah: _selectedAyah,
      onAyahLongPress: onAyahLongPress,
      showInfo: false,
      paintBackground: false,
      isDigital: mushafType == 'digital',
      wordVerdicts: wordVerdicts,
      revealedWordKeys: revealedWordKeys,
    );
  }

  BoxDecoration _pageDecoration(SettingsProvider settings) => BoxDecoration(
    color: settings.backgroundColor,
    image: !settings.isDarkMode && settings.backgroundColorMode == 'old'
        ? const DecorationImage(
            image: AssetImage('assets/images/mushaf_texture.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          )
        : null,
  );

  Widget _buildLoadingScreen(bool isDark, SettingsProvider settings) {
    return DecoratedBox(
      decoration: _pageDecoration(settings),
      child: ReaderLoadingIndicator(key: ValueKey(_pageLoadGeneration)),
    );
  }

  Widget _buildErrorScreen(bool isDark, SettingsProvider settings) {
    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.mushafTitle,
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
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_errorMessage!.contains('تحميل')) {
                  // Navigate to settings
                  context.read<UiProvider>().setTabIndex(
                    3,
                  ); // settings is index 3
                } else {
                  _loadPages();
                }
              },
              icon: Icon(
                _errorMessage!.contains('تحميل')
                    ? Icons.download_rounded
                    : Icons.refresh,
              ),
              label: Text(
                _errorMessage!.contains('تحميل')
                    ? 'الانتقال للتحميل'
                    : 'إعادة المحاولة',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: _errorMessage!.contains('تحميل')
                    ? AppColors.primary
                    : null,
                foregroundColor: _errorMessage!.contains('تحميل')
                    ? Colors.white
                    : null,
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
        title: Text(
          AppLocalizations.of(context)!.mushafTitle,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 18),
        ),
      ),
    );
  }

  // Debounce timer (reserved for future use, cancelled in dispose)
  Timer? _syncDebounce;
  int?
  _pendingContinuousPage; // أحدث صفحة مستهدفة تنتظر مزامنتها في الوضع المستمر
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
          either.fold((failure) => null, (ayahObj) {
            if (ayahObj != null && mounted) {
              context.read<QuranProvider>().updateReadingLocation(
                ayahObj.surahNumber,
                ayahObj.ayahNumber,
              );
              context.read<AudioProvider>().setContext(
                ayahObj.surahNumber,
                ayahObj.ayahNumber,
              );
            }
          });
        });
      }
    } else {
      // Madani (v1/v2): use full 604-page static map — instant, no DB needed
      final surah = MushafNavigationProvider.surahForPageFull(pageNum);
      final ayah = MushafNavigationProvider.ayahForPageFull(pageNum);
      context.read<QuranProvider>().updateReadingLocation(surah, ayah);
      context.read<AudioProvider>().setContext(surah, ayah);
    }
  }
}
