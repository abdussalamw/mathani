
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator

import '../../../core/constants/app_colors.dart';

import '../index/index_screen.dart';
import '../settings/settings_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../tafsir/tafsir_screen.dart'; 
import '../../providers/ui_provider.dart';
import '../../widgets/audio_minibar.dart';
import '../../widgets/audio_player_sheet.dart';
import 'package:provider/provider.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({Key? key}) : super(key: key);

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  DateTime? _lastPressedAt; // Added for double-back exit logic
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UiProvider>(
      builder: (context, uiProvider, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;

            // 1. If not on Home (Index=0), go to Home
            if (uiProvider.currentTabIndex != 0) {
              uiProvider.setTabIndex(0);
              return;
            }

            // 2. If on Home, check Double Tap to Exit
            final now = DateTime.now();
            final maxDuration = const Duration(seconds: 2);
            final isWarning = _lastPressedAt == null || 
                              now.difference(_lastPressedAt!) > maxDuration;

            if (isWarning) {
              _lastPressedAt = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('اضغط مرة أخرى للخروج', style: TextStyle(fontFamily: 'Tajawal')),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // 3. Exit App
            await SystemNavigator.pop();
          },
          child: Scaffold(
            extendBody: true, // Allow body to extend behind BottomNavigationBar
            extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
            appBar: (uiProvider.isImmersiveMode || uiProvider.currentTabIndex == 1) 
              ? null 
            : AppBar(
                title: Text(
                  _getScreenTitle(uiProvider),
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                backgroundColor: uiProvider.isImmersiveMode ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? const Color(0xCC2C2416) : const Color(0xCCFFFFFF)), // Transparent or semi-transparent
                elevation: 0,
              ),
          body: IndexedStack(
            index: _getCurrentScreenIndex(uiProvider),
            children: [
              const IndexScreen(),           // 0: الفهرس
              const MushafScreen(),          // 1: المصحف
              TafsirScreen(initialPage: uiProvider.currentMushafPage), // 2: التفسير
              const SettingsScreen(),        // 3: الإعدادات
            ],
          ),
          bottomNavigationBar: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: uiProvider.isImmersiveMode ? const Offset(0, 1) : Offset.zero,
            child: uiProvider.isImmersiveMode 
              ? const SizedBox.shrink() 
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (uiProvider.showAudioMinibar) const AudioMinibar(),
                    _buildBottomBar(uiProvider),
                  ],
                ),
          ),
          ),
        );
      },
    );
  }

  int _getCurrentScreenIndex(UiProvider uiProvider) {
    // uiProvider uses: 0=Index, 1=Mushaf, 2=Audio, 3=Settings
    // IndexedStack has: 0=Index, 1=Mushaf, 2=Audio, 3=Tafsir, 4=Settings
    final index = uiProvider.currentTabIndex;
    final showingTafsir = uiProvider.showingTafsir;
    
    switch (index) {
      case 0: return 0; // Index
      case 1: return showingTafsir ? 2 : 1; // Mushaf or Tafsir
      case 3: return 3; // Settings
      default: return 1;
    }
  }

  String _getScreenTitle(UiProvider uiProvider) {
    switch (uiProvider.currentTabIndex) {
      case 0: return 'فهرس السور';
      case 1: return 'المصحف الشريف';
      case 3: return 'إعدادات التطبيق';
      default: return 'مثاني';
    }
  }

  Widget _buildBottomBar(UiProvider uiProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = uiProvider.currentTabIndex;
    final showingTafsir = uiProvider.showingTafsir;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2416) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. الفهرس
              _buildNavItem(
                icon: Icons.search,
                label: 'الفهرس',
                isSelected: currentIndex == 0 && uiProvider.indexScreenTabIndex != 2,
                onTap: () => uiProvider.setTabIndex(0, indexScreenTab: 0),
              ),

              // 2. العلامات
              _buildNavItem(
                icon: Icons.bookmark_outline_rounded,
                label: 'العلامات',
                isSelected: currentIndex == 0 && uiProvider.indexScreenTabIndex == 2,
                onTap: () {
                  uiProvider.setTabIndex(0, indexScreenTab: 2);
                },
              ),
              
              // 3. المصحف/تفسير (الوسط - الرئيسية)
              _buildMainButton(
                icon: (currentIndex == 1 && !showingTafsir) ? Icons.auto_stories : Icons.menu_book,
                label: (currentIndex == 1 && !showingTafsir) ? 'تفسير' : 'المصحف',
                onTap: () {
                  if (currentIndex == 1 && !showingTafsir) {
                    uiProvider.toggleTafsir();
                  } else {
                    uiProvider.setTabIndex(1);
                    if (showingTafsir) {
                      uiProvider.toggleTafsir();
                    }
                  }
                },
              ),

              // 4. استماع (Toggle Minibar)
              _buildNavItem(
                icon: Icons.play_arrow_rounded,
                label: 'استماع',
                isSelected: uiProvider.showAudioMinibar,
                onTap: () {
                   // Ensure bar is shown
                   if (!uiProvider.showAudioMinibar) {
                      uiProvider.toggleAudioMinibar();
                   } else {
                      // If already shown, maybe open full player?
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AudioPlayerSheet(),
                      );
                   }
                },
              ),
              
              // 5. الإعدادات
              _buildNavItem(
                icon: Icons.settings_outlined,
                label: 'إعدادات',
                isSelected: currentIndex == 3,
                onTap: () => uiProvider.setTabIndex(3),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: 1, // Make sure it fits
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.golden,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10, // Slightly smaller font to fit larger icon/padding
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
