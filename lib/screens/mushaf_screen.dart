
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/database/collections.dart';
import '../providers/settings_provider.dart';
import '../providers/quran_provider.dart';

class MushafScreen extends StatefulWidget {
  final Surah? surah; // Optional, might be null if opening last read

  const MushafScreen({Key? key, this.surah}) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  bool _barsVisible = true;
  List<Ayah> _ayahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAyahs();
  }
  
  Future<void> _loadAyahs() async {
    if (widget.surah != null) {
      // Use addPostFrameCallback to ensure context is valid if running immediately
      WidgetsBinding.instance.addPostFrameCallback((_) async {
         final ayahs = await context.read<QuranProvider>().getAyahsForSurah(widget.surah!.number);
         if (mounted) {
           setState(() {
             _ayahs = ayahs;
             _isLoading = false;
           });
         }
      });
    } else {
      // Handle "Continue Reading" logic later
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _toggleBars() {
    setState(() {
      _barsVisible = !_barsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Content Layer
          GestureDetector(
            onTap: _toggleBars,
            child: SafeArea(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _ayahs.isEmpty
                  ? const Center(child: Text('لا توجد آيات لعرضها'))
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    itemCount: _ayahs.length + 1, // +1 for Basmala header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Basmala (Hide for Tawbah - Surah 9)
                        // If surah is null (placeholder), show Basmala
                        if (widget.surah?.number == 9) return const SizedBox.shrink();
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24, top: 40), // Top margin for bar space
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.golden.withOpacity(0.5), width: 1),
                              bottom: BorderSide(color: AppColors.golden.withOpacity(0.5), width: 1),
                            ),
                          ),
                          child: Text(
                            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      final ayah = _ayahs[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: ayah.textUthmani,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              TextSpan(
                                text: ' ﴿${ayah.ayahNumber}﴾',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.golden,
                                  fontFamily: 'Amiri', // Ensure brackets use Amiri too
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    },
                  ),
            ),
          ),

          // Top Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _barsVisible ? 0 : -90,
            left: 0,
            right: 0,
            child: Container(
              height: 85,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward), // Back button (RTL arrow forward acts as back for Arabic UI usually implies Right to Left movement, but here standard back is needed) 
                    // Wait, in RTL, Back is usually ArrowForward (pointing right).
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: AppColors.golden),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'سورة ${widget.surah?.nameArabic ?? ""}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                      ),
                      Text(
                        'الجزء ${widget.surah?.juzNumber ?? ""}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Balance the row visually
                  const SizedBox(width: 48), 
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return IconButton(
                        icon: Icon(
                          settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: AppColors.golden,
                        ),
                        onPressed: () {
                          settings.toggleTheme();
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _barsVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
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
                  _buildBottomNavItem(context, Icons.library_books, 'التفسير', false),
                  _buildBottomNavItem(context, Icons.headphones, 'استماع', false),
                  _buildBottomNavItem(context, Icons.menu_book, 'تلاوة', true),
                ],
              ),
            ),
          ),
        ],
      ),
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
