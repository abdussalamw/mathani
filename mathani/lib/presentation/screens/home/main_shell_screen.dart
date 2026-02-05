
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../surah_list/surah_list_screen.dart';
import '../settings/settings_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../tafsir/tafsir_screen.dart'; 
import '../audio_player/audio_player_screen.dart'; 
import '../bookmarks/bookmarks_screen.dart'; 
import '../../providers/ui_provider.dart';
import '../../widgets/audio_minibar.dart';
import 'package:provider/provider.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({Key? key}) : super(key: key);

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // bool _isPlayingAudio = false; // We can remove this if handled by providers
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UiProvider>(
      builder: (context, uiProvider, child) {
        return Scaffold(
          extendBody: true, // Allow body to extend behind BottomNavigationBar
          extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
          appBar: (uiProvider.isImmersiveMode || uiProvider.currentTabIndex == 2) 
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
            children: const [
              SurahListScreen(),       // 0: الفهرس
              BookmarksScreen(),       // 1: العلامات
              MushafScreen(),          // 2: المصحف (Starts at Page 1)
              AudioPlayerScreen(),     // 3: الاستماع
              TafsirScreen(),          // 4: التفسير
              SettingsScreen(),        // 5: الإعدادات
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
                    AudioMinibar(),
                    _buildBottomBar(uiProvider),
                  ],
                ),
          ),
        );
      },
    );
  }

  int _getCurrentScreenIndex(UiProvider uiProvider) {
    final index = uiProvider.currentTabIndex;
    final showingTafsir = uiProvider.showingTafsir;
    
    switch (index) {
      case 0: return 0; // Index
      case 1: return 1; // Bookmarks
      case 2: return showingTafsir ? 4 : 2; // Mushaf or Tafsir
      case 3: return 3; // Audio
      case 4: return 5; // Settings
      default: return 2;
    }
  }

  String _getScreenTitle(UiProvider uiProvider) {
    switch (uiProvider.currentTabIndex) {
      case 0: return 'فهرس السور';
      case 1: return 'العلامات المرجعية';
      case 3: return 'الاستماع والتلاوة';
      case 4: return 'إعدادات التطبيق';
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
              // 1. الفهرس (البحث)
              _buildNavItem(
                icon: Icons.search,
                label: 'الفهرس',
                isSelected: currentIndex == 0,
                onTap: () => uiProvider.setTabIndex(0),
              ),

              // 2. العلامات
              _buildNavItem(
                icon: Icons.bookmark_outline_rounded,
                label: 'العلامات',
                isSelected: currentIndex == 1,
                onTap: () => uiProvider.setTabIndex(1),
              ),
              
              // 3. تلاوة/تفسير (الوسط - الرئيسية)
              _buildMainButton(
                icon: showingTafsir ? Icons.menu_book : Icons.auto_stories,
                label: showingTafsir ? 'المصحف' : 'تفسير',
                onTap: () => uiProvider.toggleTafsir(),
              ),

              // 4. استماع
              _buildNavItem(
                icon: Icons.headphones_outlined,
                label: 'استماع',
                isSelected: currentIndex == 3,
                onTap: () => uiProvider.setTabIndex(3),
              ),
              
              // 5. الإعدادات
              _buildNavItem(
                icon: Icons.settings_outlined,
                label: 'الإعدادات',
                isSelected: currentIndex == 4,
                onTap: () => uiProvider.setTabIndex(4),
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
