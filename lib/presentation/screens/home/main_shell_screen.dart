
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:mathani/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';

import '../index/index_screen.dart';
import '../settings/settings_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../tafsir/tafsir_screen.dart'; 
import '../../providers/ui_provider.dart';
import '../../providers/settings_provider.dart';
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

            // 1. If not on Mushaf (Index=1), go to Mushaf
            if (uiProvider.currentTabIndex != 1) {
              uiProvider.setTabIndex(1);
              return;
            }

            // If we are on Mushaf but showing Tafsir, go back to Mushaf
            if (uiProvider.showingTafsir) {
              uiProvider.toggleTafsir();
              return;
            }

            // 2. If on Mushaf, check Double Tap to Exit
            final now = DateTime.now();
            final maxDuration = const Duration(seconds: 2);
            final isWarning = _lastPressedAt == null || 
                              now.difference(_lastPressedAt!) > maxDuration;

            if (isWarning) {
              _lastPressedAt = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.pressBackToExit, style: const TextStyle(fontFamily: 'Tajawal')),
                  duration: const Duration(seconds: 2),
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
            appBar: (uiProvider.currentTabIndex == 1) 
              ? null 
            : AppBar(
                title: Text(
                  _getScreenTitle(uiProvider),
                  style: const TextStyle(
                    fontFamily: 'Tajawal', 
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateText,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                backgroundColor: uiProvider.isImmersiveMode 
                    ? Colors.transparent 
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF131315) 
                        : AppColors.brandBackground),
                elevation: 0,
                scrolledUnderElevation: 0, // Prevent color change on scroll
              ),
          body: Stack(
            children: [
              IndexedStack(
                index: _getCurrentScreenIndex(uiProvider),
                children: [
                  const IndexScreen(),           // 0: الفهرس
                  MushafScreen(initialPage: context.read<SettingsProvider>().lastPage), // 1: المصحف
                  TafsirScreen(initialPage: uiProvider.currentMushafPage), // 2: التفسير
                  const SettingsScreen(),        // 3: الإعدادات
                ],
              ),
              
              // Full Audio Player Overlay (positioned above bottom bar)
              if (uiProvider.showFullAudioPlayer && !uiProvider.isImmersiveMode)
                Positioned(
                  bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 10,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy > 10) uiProvider.setShowFullAudioPlayer(false);
                    },
                    child: const AudioPlayerSheet(),
                  ),
                ),
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
    final l10n = AppLocalizations.of(context)!;
    switch (uiProvider.currentTabIndex) {
      case 0: return l10n.surahIndexTitle;
      case 1: return l10n.mushafTitle;
      case 3: return l10n.appSettingsTitle;
      default: return l10n.appName;
    }
  }

  Widget _buildBottomBar(UiProvider uiProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = uiProvider.currentTabIndex;
    final showingTafsir = uiProvider.showingTafsir;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131315) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), // High density
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. الفهرس
              _buildNavItem(
                icon: Icons.grid_view_rounded, // More modern icon
                label: AppLocalizations.of(context)!.indexTab,
                isSelected: currentIndex == 0 && uiProvider.indexScreenTabIndex != 2,
                onTap: () => uiProvider.setTabIndex(0, indexScreenTab: 0),
              ),

              // 2. العلامات
              _buildNavItem(
                icon: Icons.bookmarks_outlined,
                label: AppLocalizations.of(context)!.bookmarksTab,
                isSelected: currentIndex == 0 && uiProvider.indexScreenTabIndex == 2,
                onTap: () {
                  uiProvider.setTabIndex(0, indexScreenTab: 2);
                },
              ),
              
              // 3. المصحف (المركزية)
              _buildMainButton(
                icon: (currentIndex == 1 && !showingTafsir) ? Icons.menu_book : Icons.auto_stories,
                label: (currentIndex == 1 && !showingTafsir) ? AppLocalizations.of(context)!.tafsirTab : AppLocalizations.of(context)!.mushafTab,
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

               // 4. استماع
               _buildNavItem(
                 icon: uiProvider.showFullAudioPlayer ? Icons.headphones : Icons.headphones_outlined,
                 label: AppLocalizations.of(context)!.listeningTab,
                 isSelected: uiProvider.showFullAudioPlayer,
                 onTap: () {
                    if (!uiProvider.showAudioMinibar) {
                       uiProvider.toggleAudioMinibar();
                    }
                    uiProvider.toggleFullAudioPlayer();
                 },
               ),
              
              // 5. الإعدادات
              _buildNavItem(
                icon: Icons.settings_outlined,
                label: AppLocalizations.of(context)!.settingsTab,
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
                color: AppColors.primary.withOpacity(0.4),
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
