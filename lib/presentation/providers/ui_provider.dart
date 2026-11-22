import 'package:material_ui/material_ui.dart';

import '../../data/providers/mushaf_navigation_provider.dart';

class UiProvider with ChangeNotifier {
  int _currentTabIndex = 1; // Default to Mushaf
  int? _pageToJump;
  bool _showingTafsir = false;
  bool _isImmersiveMode = false;
  int _indexScreenTabIndex = 0; // 0=Surahs, 1=Juz, 2=Bookmarks
  bool _showAudioMinibar = false;
  bool _showFullAudioPlayer = false;
  bool _hasNpu = true;

  // ✅ تم إزالة surahToPage المشفر - يتم استخدام MushafNavigationProvider الآن

  int _currentMushafPage = 1;

  // ─── حالة التسميع الذكي ───
  bool _showRecitationMinibar = false;
  bool _isRecitationActive = false; // قيد التسجيل حالياً

  int get currentTabIndex => _currentTabIndex;
  int? get pageToJump => _pageToJump;
  bool get showingTafsir => _showingTafsir;
  bool get isImmersiveMode => _isImmersiveMode;
  int get indexScreenTabIndex => _indexScreenTabIndex;
  int get currentMushafPage => _currentMushafPage;
  bool get showAudioMinibar => _showAudioMinibar;
  bool get showFullAudioPlayer => _showFullAudioPlayer;
  bool get hasNpu => _hasNpu;
  bool get showRecitationMinibar => _showRecitationMinibar;
  bool get isRecitationActive => _isRecitationActive;

  void toggleAudioMinibar() {
    _showAudioMinibar = !_showAudioMinibar;
    if (!_showAudioMinibar) _showFullAudioPlayer = false;
    notifyListeners();
  }

  void toggleFullAudioPlayer() {
    _showFullAudioPlayer = !_showFullAudioPlayer;
    if (_showFullAudioPlayer) _isImmersiveMode = false;
    notifyListeners();
  }

  void setShowFullAudioPlayer(bool show) {
    _showFullAudioPlayer = show;
    if (show) _isImmersiveMode = false;
    notifyListeners();
  }

  void setShowAudioMinibar(bool show) {
    _showAudioMinibar = show;
    notifyListeners();
  }

  void setHasNpu(bool value) {
    _hasNpu = value;
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
    if (index != 1) {
      // Mushaf is index 1
      _showingTafsir = false;
      _isImmersiveMode = false;
    }
    notifyListeners();
  }

  void toggleTafsir() {
    _isImmersiveMode = false;
    if (_currentTabIndex == 1) {
      // Mushaf is index 1
      _showingTafsir = !_showingTafsir;
      notifyListeners();
    } else {
      setTabIndex(1);
      _showingTafsir = false;
    }
  }

  void hideTafsir() {
    if (_showingTafsir) {
      _showingTafsir = false;
      notifyListeners();
    }
  }

  void jumpToPage(int page) {
    _isImmersiveMode = false;
    _pageToJump = page < 1 ? 1 : page;
    _currentTabIndex = 1; // Switch to Mushaf tab (index 1)
    _showingTafsir = false;
    notifyListeners();
  }

  void jumpToSurah(
    int surahNumber,
    MushafNavigationProvider navigationProvider,
  ) {
    final page = navigationProvider.getPageForSurah(surahNumber);
    if (page != null) {
      jumpToPage(page);
    }
  }

  void toggleImmersiveMode() {
    setImmersiveMode(!_isImmersiveMode);
  }

  void setImmersiveMode(bool immersive) {
    final next = immersive && _currentTabIndex == 1 && !_showingTafsir;
    if (next == _isImmersiveMode) return;
    _isImmersiveMode = next;
    if (next) _showFullAudioPlayer = false;
    notifyListeners();
  }

  void consumeJump() {
    _pageToJump = null;
  }

  // ─── دوال التسميع ───
  void toggleRecitationMinibar() {
    _showRecitationMinibar = !_showRecitationMinibar;
    if (!_showRecitationMinibar) {
      _isRecitationActive = false;
    }
    notifyListeners();
  }

  void setRecitationActive(bool active) {
    _isRecitationActive = active;
    notifyListeners();
  }

  void openRecitationMinibar() {
    if (!_showRecitationMinibar) {
      _showRecitationMinibar = true;
      _showAudioMinibar = false; // تعطيل AudioMinibar أثناء التسميع
      _showFullAudioPlayer = false;
      notifyListeners();
    }
  }

  void hideRecitationMinibar() {
    _showRecitationMinibar = false;
    _isRecitationActive = false;
    notifyListeners();
  }
}
