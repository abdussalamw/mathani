import 'package:flutter/material.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/screens/tafsir/tafsir_screen.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:provider/provider.dart';

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
    _loadPages();
  }
  
  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final pages = await _loader.loadAllPages();
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
        return AlertDialog(
          title: const Text(
            'الانتقال إلى صفحة',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'رقم الصفحة (1-604)',
            ),
            onChanged: (value) {
              selectedPage = int.tryParse(value);
            },
            onSubmitted: (value) {
              if (selectedPage != null && 
                  selectedPage! >= 1 && 
                  selectedPage! <= (_pages?.length ?? 604)) {
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
                if (selectedPage != null && 
                    selectedPage! >= 1 && 
                    selectedPage! <= (_pages?.length ?? 604)) {
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

  void _onAyahSelected(int surah, int ayah) {
    setState(() {
      _selectedSurah = surah;
      _selectedAyah = ayah;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAyahOptionsMenu(surah, ayah),
    ).whenComplete(() {
      setState(() {
        _selectedSurah = null;
        _selectedAyah = null;
      });
    });
  }

  Widget _buildAyahOptionsMenu(int surah, int ayah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2C2416) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'سورة $surah - آية $ayah', // TODO: Use proper Surah names logic later
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(
                icon: Icons.play_arrow_rounded,
                label: 'استماع',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  context.read<AudioProvider>().playAyah(_selectedSurah!, _selectedAyah!);
                  ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text(
                         'جاري تشغيل التلاوة (عبد الباسط عبد الصمد)...',
                         style: TextStyle(fontFamily: 'Tajawal'),
                       ),
                       duration: Duration(seconds: 2),
                     ),
                  );
                },
              ),
              _buildOptionButton(
                icon: Icons.menu_book_rounded,
                label: 'تفسير',
                color: AppColors.golden,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TafsirScreen(
                        surahNumber: _selectedSurah!,
                        ayahNumber: _selectedAyah!,
                      ),
                    ),
                  );
                },
              ),
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProvider, child) {
                  final isBookmarked = bookmarkProvider.isBookmarked(_selectedSurah!, _selectedAyah!);
                  return _buildOptionButton(
                    icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    label: isBookmarked ? 'محفوظ' : 'علامة',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      if (isBookmarked) {
                        bookmarkProvider.removeBookmark(_selectedSurah!, _selectedAyah!);
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('تم إزالة العلامة', style: TextStyle(fontFamily: 'Tajawal'))),
                        );
                      } else {
                        bookmarkProvider.addBookmark(_selectedSurah!, _selectedAyah!);
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('تم الحفظ في العلامات', style: TextStyle(fontFamily: 'Tajawal'))),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Handle Jump Signal
    final uiProvider = Provider.of<UiProvider>(context);
    if (uiProvider.pageToJump != null) {
      final page = uiProvider.pageToJump!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(page - 1);
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
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1410) : const Color(0xFFFFFDF5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Toggle bars visibility logic if exists
                },
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages?.length ?? 0,
                    reverse: false, // In RTL, standard order means reverse: false (Page 1 on right)
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index + 1;
                      });
                    },
                    itemBuilder: (context, index) {
                      return MushafPageWidget(
                        page: _pages![index],
                        selectedSurah: _selectedSurah,
                        selectedAyah: _selectedAyah,
                        onAyahSelected: _onAyahSelected,
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Bottom Info Bar (Page Number & Navigation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF2C2416) 
                    : Colors.white,
                boxShadow: const [
                   BoxShadow(
                    color: AppColors.black10,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الصفحة السابقة (لليسار في العربية) - Arrow Left Visual but Right Action
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentPage < (_pages?.length ?? 604)
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    tooltip: 'الصفحة التالية',
                  ),
                  
                  // معلومات الصفحة
                  Text(
                    'صفحة $_currentPage من ${_pages!.length}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  
                  // الصفحة التالية (لليمين في العربية)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _currentPage > 1
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    tooltip: 'الصفحة السابقة',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
