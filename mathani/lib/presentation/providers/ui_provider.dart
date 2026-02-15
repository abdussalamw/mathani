import 'package:flutter/material.dart';
import '../../data/providers/mushaf_navigation_provider.dart';

class UiProvider with ChangeNotifier {
  int _currentTabIndex = 1; // Default to Mushaf
  int? _pageToJump;
  bool _showingTafsir = false;
  bool _isImmersiveMode = false;
  int _indexScreenTabIndex = 0; // 0=Surahs, 1=Juz, 2=Bookmarks
  bool _showAudioMinibar = false; 

  // ✅ تم إزالة surahToPage المشفر - يتم استخدام MushafNavigationProvider الآن
  
  int _currentMushafPage = 1; // Tracks the current page in MushafScreen

  int get currentTabIndex => _currentTabIndex;
  int? get pageToJump => _pageToJump;
  bool get showingTafsir => _showingTafsir;
  bool get isImmersiveMode => _isImmersiveMode;
  int get indexScreenTabIndex => _indexScreenTabIndex;
  int get currentMushafPage => _currentMushafPage;
  bool get showAudioMinibar => _showAudioMinibar;

  void toggleAudioMinibar() {
    _showAudioMinibar = !_showAudioMinibar;
    notifyListeners();
  }

  void setShowAudioMinibar(bool show) {
    _showAudioMinibar = show;
    notifyListeners();
  }

  void setCurrentMushafPage(int page) {
    if (_currentMushafPage != page) {
      _currentMushafPage = page;
      // Do not notifyListeners() here to avoid rebuilding everything on every swipe?
      // Actually, main_shell needs to rebuild to pass the new page to Tafsir.
      // So yes, we should notify, but maybe debounce it or ensure it doesn't cause lag.
      // For now, let's notify.
      notifyListeners();
    }
  }
  
  void setTabIndex(int index, {int? indexScreenTab}) {
    _currentTabIndex = index;
    if (indexScreenTab != null) {
      _indexScreenTabIndex = indexScreenTab.clamp(0, 2);
    }
    if (index != 1) { // Mushaf is index 1
       _showingTafsir = false;
       _isImmersiveMode = false;
    }
    notifyListeners();
  }
  
  void toggleTafsir() {
    if (_currentTabIndex == 1) { // Mushaf is index 1
      _showingTafsir = !_showingTafsir;
      notifyListeners();
    } else {
      setTabIndex(1);
      _showingTafsir = false;
    }
  }

  void jumpToPage(int page) {
    _pageToJump = page;
    _currentTabIndex = 1; // Switch to Mushaf tab (index 1)
    _showingTafsir = false;
    notifyListeners();
  }

  void jumpToSurah(int surahNumber, MushafNavigationProvider navigationProvider) {
    final page = navigationProvider.getPageForSurah(surahNumber);
    if (page != null) {
      jumpToPage(page);
    }
  }
  
  void toggleImmersiveMode() {
    _isImmersiveMode = !_isImmersiveMode;
    notifyListeners();
  }

  void consumeJump() {
    _pageToJump = null;
  }
}
