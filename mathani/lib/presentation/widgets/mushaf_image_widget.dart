import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/image_page_loader.dart';
import '../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/quran_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/bookmark_provider.dart';
import '../../data/providers/mushaf_navigation_provider.dart';
import '../../presentation/providers/ui_provider.dart';
import '../../core/constants/responsive_constants.dart';

class MushafImageWidget extends StatefulWidget {
  final int pageNumber;
  final String mushafId;
  final String baseUrl;
  final String imageExtension;

  const MushafImageWidget({
    Key? key,
    required this.pageNumber,
    required this.mushafId,
    required this.baseUrl,
    this.imageExtension = 'jpg',
  }) : super(key: key);

  @override
  State<MushafImageWidget> createState() => _MushafImageWidgetState();
}

class _MushafImageWidgetState extends State<MushafImageWidget> {
  File? _imageFile;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(MushafImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.mushafId != widget.mushafId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _imageFile = null;
      });
    }

    try {
      final file = await ImagePageLoader.getPageImage(
        widget.mushafId,
        widget.pageNumber,
        widget.baseUrl,
        extension: widget.imageExtension,
      );

      if (mounted) {
        setState(() {
          _imageFile = file;
          _isLoading = false;
          _hasError = file == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _convertToArabicNumbers(int number) {
    if (number == 0) return '٠';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return number.toString();

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
        result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Constants
    final topBarHeight = ResponsiveConstants.getTopBarHeight(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    
    return Consumer<MushafNavigationProvider>(
      builder: (context, navProvider, child) {
        // Get dynamic page info
        final pageInfo = navProvider.getPageInfo(widget.pageNumber);
        final juzNumber = pageInfo?.juz ?? 1;
        final surahs = pageInfo?.surahs ?? [];
        
        // Get first surah on this page for display
        // Prefer startSurah (from Ayahs) as it's more reliable than the summary list
        int? firstSurah = (pageInfo != null && pageInfo.startSurah > 0) 
             ? pageInfo.startSurah 
             : (surahs.isNotEmpty ? surahs.first : null);
        
        return Column(
          children: [
            // 1. Top Bar
            SizedBox(
              height: topBarHeight,
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Right: Juz (QCF4_BSML) - Clickable
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              // Navigate to Juz index (tab 1 in IndexScreen)
                              final uiProvider = Provider.of<UiProvider>(context, listen: false);
                              uiProvider.setTabIndex(0, indexScreenTab: 1);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                String.fromCharCode(0xF1D8 + (juzNumber - 1)),
                                style: const TextStyle(
                                  fontFamily: 'QCF4_BSML',
                                  fontSize: 20,
                                  color: AppColors.primary,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Center: Surah Name (QCF4_BSML) - Clickable
                      Expanded(
                        child: Center(
                          child: firstSurah != null
                              ? InkWell(
                                  onTap: () {
                                    // Navigate to Surah index (tab 0 in IndexScreen)
                                    final uiProvider = Provider.of<UiProvider>(context, listen: false);
                                    uiProvider.setTabIndex(0);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      String.fromCharCode(0xF100 + (firstSurah - 1)),
                                      style: const TextStyle(
                                        fontFamily: 'QCF4_BSML',
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ),

                      // Left: Theme Toggle + Bookmark + Page Number
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Theme Toggle
                              Consumer<SettingsProvider>(
                                builder: (context, settings, child) {
                                  final isDark = settings.isDarkMode;
                                  return InkWell(
                                    onTap: () => settings.toggleTheme(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        isDark ? Icons.light_mode : Icons.dark_mode,
                                        size: 22,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 4),
                              
                              // Bookmark
                              Consumer<BookmarkProvider>(
                                builder: (context, bookmarks, child) {
                                  final isBookmarked = bookmarks.isPageBookmarked(widget.pageNumber);
                                  return InkWell(
                                    onTap: () => bookmarks.togglePageBookmark(widget.pageNumber),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        size: 22,
                                        color: isBookmarked ? AppColors.primary : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Page Number
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _convertToArabicNumbers(widget.pageNumber),
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  ),
                                ),
                              ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Image Content
            Expanded(
              child: _buildContent(isTablet),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(bool isTablet) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_hasError || _imageFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'فشل تحميل الصفحة',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImage,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    
    // Padding Logic
    // Bottom: 140 (Standard Nav Bar clearance)
    // Top: 0 (Header is separate now) OR extra tablet padding?
    // If we separated the Header, we don't need huge top padding inside expected, 
    // unless user wants MORE distance.
    // User said: "Between top and bottom bar".
    // We already have the Top Bar above.
    // We apply bottom padding.
    // We apply Tablet padding if needed.
    
    final contentPadding = EdgeInsets.only(
      bottom: 140, 
      left: 16, 
      right: 16,
      top: isTablet ? 20.0 : 0.0, // Extra breather for iPad below header
    );

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Determine the visual filter to apply
        Widget content = Image.file(
          _imageFile!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Center(child: Text('خطأ')),
        );

        if (settings.isDarkMode) {
          // Night Mode: Invert Colors (White -> Black, Black -> White)
          // This creates a perfect "OLED" friendly reading mode for images
          content = ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1,  0,  0, 0, 255,
               0, -1,  0, 0, 255,
               0,  0, -1, 0, 255,
               0,  0,  0, 1,   0,
            ]),
            child: content,
          );
        } else if (settings.backgroundColorMode != 'white') {
           // Paper Backgrounds (Cream / Old): Multiply Blend
           // This tints the white parts of the image to the target color 
           // while keeping the black text sharp (Mutiply logic: White * Color = Color, Black * Color = Black)
           content = ColorFiltered(
             colorFilter: ColorFilter.mode(
               settings.backgroundColor, 
               BlendMode.multiply,
             ),
             child: content,
           );
        }

        return Padding(
          padding: contentPadding,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: content,
          ),
        );
      },
    );
  }
}

