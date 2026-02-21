import 'package:flutter/material.dart';
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
    this.dragThreshold = 25.0, // ط²ظٹط§ط¯ط© ط§ظ„ط¹طھط¨ط© ظ„طھظ‚ظ„ظٹظ„ ط§ظ„ط­ط³ط§ط³ظٹط© ط§ظ„ط¹ط§ظ„ظٹط© (ظƒط§ظ†طھ 2.0)
    this.flingVelocity = 150.0, // ط²ظٹط§ط¯ط© ط³ط±ط¹ط© ط§ظ„ظ‚ط°ظپ ط§ظ„ظ…ط·ظ„ظˆط¨ط© (ظƒط§ظ†طھ 80.0)
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
  static const double _autoScrollSpeed = 2.0;
  static const Duration _autoScrollInterval = Duration(milliseconds: 16); // ~60fps
  
  // ScrollControllers ظ„ظ„طµظپط­ط§طھ ط§ظ„ظپط±ط¯ظٹط© (ظ„ظ„ظˆط¶ط¹ Hybrid)
  final Map<int, ScrollController> _innerScrollControllers = {};
  
  // Bi-directional Drag State (ظ„ظ„طھظ†ظ‚ظ„ ط«ظ†ط§ط¦ظٹ ط§ظ„ط£ط¨ط¹ط§ط¯)
  double _secondaryOffset = 0.0;
  bool _isSecondaryDragging = false;
  int? _secondaryTargetPage;
  late AnimationController _secondaryAnimController;
  
  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    
    _secondaryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
      
      if (currentType == 'image') {
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
      child: Container(
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

  // --- ظ†ط¸ط§ظ… Auto Scroll ط§ظ„ظ…ط­ط³ظ† ---
  void _toggleAutoScroll(SettingsProvider settings) {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      // ط¥ط°ط§ ظ„ظ… ظ†ظƒظ† ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ط±ط£ط³ظٹ ط§ظ„ظ…ط³طھظ…ط±طŒ ظ†ظ†طھظ‚ظ„ ط¥ظ„ظٹظ‡ ط£ظˆظ„ط§ظ‹
      if (!settings.isVerticalContinuousMode) {
        settings.setNavigationMode(2); // 2 is Vertical Continuous
      }
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (!mounted) return;
    setState(() {
      _isAutoScrolling = true;
    });
    
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final settings = context.read<SettingsProvider>();
      final currentController = _innerScrollControllers[_currentPage];
      
      // ط§ظ„ظˆط¶ط¹ ط§ظ„ظ‡ط¬ظٹظ†: ظ†طھظ…ط±ط± ط¯ط§ط®ظ„ ط§ظ„طµظپط­ط© ط£ظˆظ„ط§ظ‹
      if (settings.isHybridMode && currentController != null && currentController.hasClients) {
        final maxScroll = currentController.position.maxScrollExtent;
        final currentScroll = currentController.offset;
        
        if (currentScroll < maxScroll) {
          // ظ†طھظ…ط±ط± ط¯ط§ط®ظ„ ط§ظ„طµظپط­ط© ط§ظ„ط­ط§ظ„ظٹط©
          currentController.jumpTo(currentScroll + _autoScrollSpeed);
          return;
        }
      }
      
      // ط¥ط°ط§ ظˆطµظ„ظ†ط§ ظ„ظ„ظ†ظ‡ط§ظٹط© ط£ظˆ ظ„ظٹط³ ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ‡ط¬ظٹظ†طŒ ظ†ظ†طھظ‚ظ„ ظ„ظ„طµظپط­ط© ط§ظ„طھط§ظ„ظٹط©
      if (_pageController.hasClients) {
        final maxPage = (_pages?.length ?? 604) - 1;
        final currentPageIndex = _pageController.page?.round() ?? _currentPage - 1;
        
        if (currentPageIndex < maxPage) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _stopAutoScroll();
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    if (mounted && _isAutoScrolling) {
      setState(() {
        _isAutoScrolling = false;
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
      _syncDebounce?.cancel();
      _autoScrollTimer?.cancel();
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
    
    // ظ…ظ†ط¹ ط§ظ„طھط£ط«ظٹط± ط¥ط°ط§ ظƒط§ظ† ط§ظ„ط³ط­ط¨ طµط؛ظٹط±ط§ظ‹ ط¬ط¯ط§ظ‹ ظپظٹ ط§ظ„ط¨ط¯ط§ظٹط© ظ„طھط¬ظ†ط¨ ط§ظ„ط§ظ‡طھط²ط§ط²
    if (!_isSecondaryDragging && delta.abs() < 1) return;

    setState(() {
      _secondaryOffset += delta;
      _isSecondaryDragging = true;
      
      // طھط­ط¯ظٹط¯ ط§ظ„طµظپط­ط© ط§ظ„ظ…ط³طھظ‡ط¯ظپط© (ط¯ط§ط¦ظ…ط§ظ‹ طµظپط­ط© ظˆط§ط­ط¯ط© ظپظ‚ط· ط¨ط¹ظٹط¯ط§ظ‹ ط¹ظ† ط§ظ„ط­ط§ظ„ظٹط©)
      if (_secondaryOffset < 0) {
        _secondaryTargetPage = _currentPage + 1;
      } else if (_secondaryOffset > 0) {
        _secondaryTargetPage = _currentPage - 1;
      }
      
      // ط§ظ„طھط§ظƒط¯ ظ…ظ† ط­ط¯ظˆط¯ ط§ظ„طµظپط­ط§طھ
      final maxPages = _pages?.length ?? 604;
      if (_secondaryTargetPage != null) {
        if (_secondaryTargetPage! < 1) _secondaryTargetPage = 1;
        if (_secondaryTargetPage! > maxPages) _secondaryTargetPage = maxPages;
        
        // ط¥ط°ط§ ظƒط§ظ†طھ ط§ظ„طµظپط­ط© ط§ظ„ظ…ط³طھظ‡ط¯ظپط© ظ‡ظٹ ظ†ظپط³ظ‡ط§ ط§ظ„ط­ط§ظ„ظٹط©طŒ ظ†ط¬ط¹ظ„ظ‡ط§ null
        if (_secondaryTargetPage == _currentPage) _secondaryTargetPage = null;
      }
    });
  }

  void _handleSecondaryDragEnd(DragEndDetails details, SettingsProvider settings) {
    if (!_isSecondaryDragging) return;
    
    final isHorizontal = settings.isHorizontalMode;
    final screenDimension = isHorizontal 
        ? MediaQuery.of(context).size.height 
        : MediaQuery.of(context).size.width;
        
    // ط±ظپط¹ ط§ظ„ط¹طھط¨ط© ط¥ظ„ظ‰ 20% ظ„ط¶ظ…ط§ظ† ط£ظ† ط§ظ„ظ…ط³طھط®ط¯ظ… ظٹط±ظٹط¯ ظپط¹ظ„ط§ظ‹ ط§ظ„طھظ‚ظ„ظٹط¨
    final threshold = screenDimension * 0.20; 
    final velocity = isHorizontal 
        ? details.velocity.pixelsPerSecond.dy 
        : details.velocity.pixelsPerSecond.dx;
    
    bool shouldFlip = _secondaryTargetPage != null && (
      _secondaryOffset.abs() > threshold || velocity.abs() > 700
    );
    
    if (shouldFlip) {
      double target = _secondaryOffset > 0 ? screenDimension : -screenDimension;
      _animateSecondaryTo(target).then((_) {
        if (mounted) {
          _pageController.jumpToPage(_secondaryTargetPage! - 1);
          setState(() {
            _isSecondaryDragging = false;
            _secondaryOffset = 0;
            _secondaryTargetPage = null;
          });
        }
      });
    } else {
      _animateSecondaryTo(0).then((_) {
        if (mounted) {
          setState(() {
            _isSecondaryDragging = false;
            _secondaryOffset = 0;
            _secondaryTargetPage = null;
          });
        }
      });
    }
  }

  Future<void> _animateSecondaryTo(double target) async {
    final animation = Tween<double>(
      begin: _secondaryOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimController,
      curve: Curves.easeOutCubic,
    ));

    void listener() {
      setState(() {
        _secondaryOffset = animation.value;
      });
    }

    animation.addListener(listener);
    await _secondaryAnimController.forward(from: 0);
    animation.removeListener(listener);
  }

  Widget _buildSecondaryOverlay(SettingsProvider settings, UiProvider uiProvider) {
    if (!_isSecondaryDragging && _secondaryOffset == 0) return const SizedBox.shrink();
    
    final isHorizontal = settings.isHorizontalMode;
    final size = MediaQuery.of(context).size;
    
    // ط§ظ„طµظپط­ط© ط§ظ„ط­ط§ظ„ظٹط©
    final currentPageWidget = _buildPageItem(context, _currentPage - 1, settings, uiProvider);
    
    // ط§ظ„طµظپط­ط© ط§ظ„ظ…ط³طھظ‡ط¯ظپط©
    Widget? targetPageWidget;
    if (_secondaryTargetPage != null) {
      targetPageWidget = _buildPageItem(context, _secondaryTargetPage! - 1, settings, uiProvider);
    }
    
    return Stack(
      children: [
        // ط®ظ„ظپظٹط© ظ„ط¥ط®ظپط§ط، PageView ط£ط«ظ†ط§ط، ط§ظ„ط­ط±ظƒط©
        Container(color: settings.backgroundColor),
        
        // ط§ظ„طµظپط­ط© ط§ظ„ظ…ط³طھظ‡ط¯ظپط© (طھط£طھظٹ ظ…ظ† ط§ظ„ط®ظ„ظپ ط£ظˆ ط£ظ…ط§ظ…)
        if (targetPageWidget != null)
          Transform.translate(
            offset: isHorizontal 
                ? Offset(0, _secondaryOffset > 0 ? _secondaryOffset - size.height : _secondaryOffset + size.height)
                : Offset(_secondaryOffset > 0 ? _secondaryOffset - size.width : _secondaryOffset + size.width, 0),
            child: targetPageWidget,
          ),
          
        // ط§ظ„طµظپط­ط© ط§ظ„ط­ط§ظ„ظٹط© ظ…ط¹ ط¸ظ„
        Transform.translate(
          offset: isHorizontal ? Offset(0, _secondaryOffset) : Offset(_secondaryOffset, 0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                if (_secondaryOffset != 0)
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
      return _buildLoadingScreen(isDark);
    }
    
    if (_errorMessage != null) {
      return _buildErrorScreen(isDark);
    }
    
    if (_pages == null || _pages!.isEmpty) {
      return _buildEmptyScreen(isDark);
    }
    
    int totalPages = 604;
    try {
      final currentId = mushafMetadata.currentMushafId;
      final mushaf = mushafMetadata.availableMushafs.firstWhere((m) => m.identifier == currentId);
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
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                     if (_isAutoScrolling) {
                        // ط¶ط؛ط·ط© ظˆط§ط­ط¯ط© طھظˆظ‚ظپ ط£ظˆ طھط³طھط£ظ†ظپ ط§ظ„ط­ط±ظƒط© ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ…طھط­ط±ظƒ
                        setState(() {
                          _isAutoScrolling = !_isAutoScrolling;
                        });
                        if (_isAutoScrolling) _startAutoScroll(); else _autoScrollTimer?.cancel();
                     } else {
                        Provider.of<UiProvider>(context, listen: false).toggleImmersiveMode();
                     }
                  },
                  onDoubleTap: () {
                    final settings = context.read<SettingsProvider>();
                    if (settings.isVerticalContinuousMode) {
                      // ط¥ط°ط§ ظƒط§ظ† ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ…طھط­ط±ظƒطŒ ظ†ظ‚ظˆظ… ط¨ط¥ظٹظ‚ط§ظپظ‡ ظˆط§ظ„ط¹ظˆط¯ط© ظ„ظ„ظˆط¶ط¹ ط§ظ„ط£ظپظ‚ظٹ
                      _stopAutoScroll();
                      settings.setNavigationMode(0); // ط§ظ„ط¹ظˆط¯ط© ظ„ظ„ظˆط¶ط¹ ط§ظ„ط£ظپظ‚ظٹ (ظٹظ…ظٹظ† ظٹط³ط§ط±)
                    } else {
                      // ط¥ط°ط§ ظ„ظ… ظٹظƒظ†طŒ ظ†ظپط¹ظ„ظ‡ ظˆظ†ط¨ط¯ط£ ط§ظ„ط­ط±ظƒط©
                      _toggleAutoScroll(settings);
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
          if (_isAutoScrolling)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_mode,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          
          // ط§ظ„ط´ط±ظٹط· ط§ظ„ط¹ظ„ظˆظٹ ط§ظ„ط«ط§ط¨طھ (ظٹط¸ظ‡ط± ظپظ‚ط· ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ…طھط­ط±ظƒ)
          if (settings.isVerticalContinuousMode) 
            Positioned(
              top: 0, left: 0, right: 0,
              height: ResponsiveConstants.getTopBarHeight(context),
              child: Container(
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
        onAyahSelected: _onAyahInteraction,
        onAyahLongPress: _onAyahInteraction,
        showInfo: !settings.isVerticalContinuousMode, // ط¥ط®ظپط§ط، ط§ظ„ط´ط±ظٹط· ط§ظ„ط¯ط§ط®ظ„ظٹ ظپظٹ ط§ظ„ظˆط¶ط¹ ط§ظ„ظ…ط³طھظ…ط±
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
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_isAutoScrolling) {
          _stopAutoScroll();
          return;
        }
        uiProvider.toggleImmersiveMode();
        _updateSystemUI();
      },
      child: pageContent,
    );
  }
  
  Widget _buildLoadingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
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
  
  Widget _buildErrorScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
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
              onPressed: _loadPages,
              icon: const Icon(Icons.refresh),
              label: const Text('ط¥ط¹ط§ط¯ط© ط§ظ„ظ…ط­ط§ظˆظ„ط©'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
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
  bool _audioListenerAdded = false; // guard against duplicate listeners

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
