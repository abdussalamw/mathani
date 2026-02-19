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

/// ScrollPhysics مخصص لضمان التنقل بين الصفحات بدقة (صفحة واحدة لكل تمريرة)
class SensitivePageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;
  final double flingVelocity;

  const SensitivePageScrollPhysics({
    ScrollPhysics? parent,
    this.dragThreshold = 25.0, // زيادة العتبة لتقليل الحساسية العالية (كانت 2.0)
    this.flingVelocity = 150.0, // زيادة سرعة القذف المطلوبة (كانت 80.0)
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

  // Auto Scroll State
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  static const double _autoScrollSpeed = 2.0;
  static const Duration _autoScrollInterval = Duration(milliseconds: 16); // ~60fps
  
  // ScrollControllers للصفحات الفردية (للوضع Hybrid)
  final Map<int, ScrollController> _innerScrollControllers = {};
  
  // Bi-directional Drag State (للتنقل ثنائي الأبعاد)
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
         final targetIndex = page - 1;
         if (_pageController.hasClients) {
            _pageController.animateToPage(
              targetIndex, 
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

  // شريط علوي ثابت للوضع المتحرك
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
          // نحن نحتاج فقط للشريط العلوي من هذا الـ Widget، لذا سنجعل المحتوى فارغاً أو نمرر تعليمات بذلك
          // لكن الأبسط في الوقت الحالي هو استخراج الـ Header فقط إذا لزم الأمر مستقبلاً
        ),
      ),
    );
  }

  // --- نظام Auto Scroll المحسن ---
  void _toggleAutoScroll(SettingsProvider settings) {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      // إذا لم نكن في الوضع الرأسي المستمر، ننتقل إليه أولاً
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
      
      // الوضع الهجين: نتمرر داخل الصفحة أولاً
      if (settings.isHybridMode && currentController != null && currentController.hasClients) {
        final maxScroll = currentController.position.maxScrollExtent;
        final currentScroll = currentController.offset;
        
        if (currentScroll < maxScroll) {
          // نتمرر داخل الصفحة الحالية
          currentController.jumpTo(currentScroll + _autoScrollSpeed);
          return;
        }
      }
      
      // إذا وصلنا للنهاية أو ليس في الوضع الهجين، ننتقل للصفحة التالية
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
      context.read<AudioProvider>().removeListener(_onAudioStateChange);
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

  // --- منطق التنقل ثنائي الأبعاد (Bi-directional Navigation) ---

  void _handleSecondaryDragUpdate(DragUpdateDetails details, SettingsProvider settings) {
    if (_isAutoScrolling || settings.isVerticalContinuousMode || settings.isHybridMode) return;
    
    final isHorizontal = settings.isHorizontalMode;
    double delta = isHorizontal ? details.delta.dy : details.delta.dx;
    
    // منع التأثير إذا كان السحب صغيراً جداً في البداية لتجنب الاهتزاز
    if (!_isSecondaryDragging && delta.abs() < 1) return;

    setState(() {
      _secondaryOffset += delta;
      _isSecondaryDragging = true;
      
      // تحديد الصفحة المستهدفة (دائماً صفحة واحدة فقط بعيداً عن الحالية)
      if (_secondaryOffset < 0) {
        _secondaryTargetPage = _currentPage + 1;
      } else if (_secondaryOffset > 0) {
        _secondaryTargetPage = _currentPage - 1;
      }
      
      // التاكد من حدود الصفحات
      final maxPages = _pages?.length ?? 604;
      if (_secondaryTargetPage != null) {
        if (_secondaryTargetPage! < 1) _secondaryTargetPage = 1;
        if (_secondaryTargetPage! > maxPages) _secondaryTargetPage = maxPages;
        
        // إذا كانت الصفحة المستهدفة هي نفسها الحالية، نجعلها null
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
        
    // رفع العتبة إلى 20% لضمان أن المستخدم يريد فعلاً التقليب
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
    
    // الصفحة الحالية
    final currentPageWidget = _buildPageItem(context, _currentPage - 1, settings, uiProvider);
    
    // الصفحة المستهدفة
    Widget? targetPageWidget;
    if (_secondaryTargetPage != null) {
      targetPageWidget = _buildPageItem(context, _secondaryTargetPage! - 1, settings, uiProvider);
    }
    
    return Stack(
      children: [
        // خلفية لإخفاء PageView أثناء الحركة
        Container(color: settings.backgroundColor),
        
        // الصفحة المستهدفة (تأتي من الخلف أو أمام)
        if (targetPageWidget != null)
          Transform.translate(
            offset: isHorizontal 
                ? Offset(0, _secondaryOffset > 0 ? _secondaryOffset - size.height : _secondaryOffset + size.height)
                : Offset(_secondaryOffset > 0 ? _secondaryOffset - size.width : _secondaryOffset + size.width, 0),
            child: targetPageWidget,
          ),
          
        // الصفحة الحالية مع ظل
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
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                     if (_isAutoScrolling) {
                        // ضغطة واحدة توقف أو تستأنف الحركة في الوضع المتحرك
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
                      // إذا كان في الوضع المتحرك، نقوم بإيقافه والعودة للوضع الأفقي
                      _stopAutoScroll();
                      settings.setNavigationMode(0); // العودة للوضع الأفقي (يمين يسار)
                    } else {
                      // إذا لم يكن، نفعله ونبدأ الحركة
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
                            setState(() {
                              _currentPage = index + 1;
                            });
                            _syncPageWithProvider(index + 1);
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
          
          // Audio Mini Bar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AudioMinibar(),
          ),
          
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
          
          // الشريط العلوي الثابت (يظهر فقط في الوضع المتحرك)
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
                  hideContent: true, // إخفاء محتوى الصفحة والاكتفاء بالشريط العلوي
                ),
              ),
            ),

          // Secondary Drag Overlay (التنقل ثنائي الأبعاد - يعمل فقط في وضع الصفحات)
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
    
    // إنشاء ScrollController للصفحة إذا لم يكن موجوداً (للوضع الهجين)
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
        showInfo: !settings.isVerticalContinuousMode, // إخفاء الشريط الداخلي في الوضع المستمر
        isDigital: isDigital,
      );
    }
    
    // في الوضع الهجين، نضيف SingleChildScrollView داخلي
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
  
  Widget _buildErrorScreen(bool isDark) {
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
  
  Widget _buildEmptyScreen(bool isDark) {
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
  
  void _syncPageWithProvider(int pageNum) {
    final navProvider = context.read<MushafNavigationProvider>();
    final pageInfo = navProvider.getPageInfo(pageNum);
    final mushafId = context.read<MushafMetadataProvider>().currentMushafId;
    
    if (mushafId == 'shamarly_15lines' && pageInfo != null) {
       final quranRepo = context.read<QuranProvider>();
       quranRepo.getAyah(pageInfo.startSurah, pageInfo.startAyah).then((either) {
          either.fold(
            (failure) => null,
            (ayah) {
              if (ayah != null && mounted) {
                context.read<UiProvider>().setCurrentMushafPage(ayah.page);
                context.read<QuranProvider>().updateReadingLocation(ayah.surahNumber, ayah.ayahNumber);
              }
            }
          );
       });
    } else {
       context.read<UiProvider>().setCurrentMushafPage(pageNum);
       
       if (pageInfo != null && pageInfo.startSurah > 0) {
          final surah = pageInfo.startSurah;
          final ayah = pageInfo.startAyah > 0 ? pageInfo.startAyah : 1;
          
          context.read<QuranProvider>().updateReadingLocation(surah, ayah);
          context.read<AudioProvider>().setContext(surah, ayah);
       }
    }
  }
}