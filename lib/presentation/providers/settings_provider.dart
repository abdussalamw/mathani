import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 24.0;
  String _fontFamily = 'Tajawal';
  String _defaultReciter = 'Minshawi_Murattal_128kbps';
  String _defaultTafsir = 'muyassar';
  bool _downloadWhilePlaying = true;
  String _backgroundColorMode = 'white'; // white, cream, old
  int _navigationMode = 0; // 0: Horizontal, 1: Vertical Paged, 2: Vertical Continuous, 3: Hybrid (Horizontal + Inner Vertical)
  String _locale = 'ar'; // Default Language
  
  // إعدادات حساسية اللمس
  double _pageDragSensitivity = 10.0; // Higher = less sensitive (was 2.0 / 25.0) — تقليب أسهل بسحبة أصغر
  double _minFlingVelocity = 90.0;    // Higher = requires more force (was 80.0 / 150.0)
  int _lastPage = 1;

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get defaultReciter => _defaultReciter;
  String get defaultTafsir => _defaultTafsir;
  bool get downloadWhilePlaying => _downloadWhilePlaying;
  String get backgroundColorMode => _backgroundColorMode;
  int get navigationMode => _navigationMode;
  int get lastPage => _lastPage;
  Locale get locale => Locale(_locale);
  String get localeCode => _locale;
  
  // Getters for navigation settings
  double get pageDragSensitivity => _pageDragSensitivity;
  double get minFlingVelocity => _minFlingVelocity;
  
  // Helper getters
  bool get isHybridMode => _navigationMode == 3;
  bool get isHorizontalMode => _navigationMode == 0;
  bool get isVerticalPagedMode => _navigationMode == 1;
  bool get isVerticalContinuousMode => _navigationMode == 2;

  Color get backgroundColor {
    if (_isDarkMode) return const Color(0xFF121212); // Modern Deep Slate
    switch (_backgroundColorMode) {
      case 'cream': return const Color(0xFFFBF9F1); // Modern Warm White
      case 'old': return const Color(0xFFF3E5AB); // Legacy Parchment
      case 'white': 
      default: return const Color(0xFFF8F9FA); // Brand Background (Modern White)
    }
  }

  // --- Actions ---

  SettingsProvider() {
    // We now depend on explicit init() call from main.dart
  }
  
  // تحميل الإعدادات
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _backgroundColorMode = prefs.getString('backgroundColorMode') ?? 'white';
    _fontSize = prefs.getDouble('fontSize') ?? 24.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Tajawal';
    _defaultReciter = prefs.getString('defaultReciter') ?? 'Minshawi_Murattal_128kbps';
    _defaultTafsir = prefs.getString('defaultTafsir') ?? 'muyassar';
    if (_defaultTafsir == 'w-moyassar') _defaultTafsir = 'muyassar';
    _downloadWhilePlaying = prefs.getBool('downloadWhilePlaying') ?? true;
    _navigationMode = prefs.getInt('navigationMode') ?? 0;
    _pageDragSensitivity = prefs.getDouble('pageDragSensitivity') ?? 10.0;
    _minFlingVelocity = prefs.getDouble('minFlingVelocity') ?? 90.0;
    _lastPage = prefs.getInt('lastPage') ?? 1;
    _locale = prefs.getString('languageCode') ?? 'ar';
    notifyListeners();
  }
  
  // تغيير اللغة
  Future<void> setLanguage(String langCode) async {
    if (_locale == langCode) return;
    _locale = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
    notifyListeners();
  }
  
  // تبديل الوضع الليلي (Explicit Set)
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  // Toggle (Legacy support)
  Future<void> toggleDarkMode() async {
    await setDarkMode(!_isDarkMode);
  }

  // Set Background Mode
  Future<void> setBackgroundColorMode(String mode) async {
    _backgroundColorMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backgroundColorMode', mode);
    notifyListeners();
  }

  Future<void> setNavigationMode(int mode) async {
    _navigationMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('navigationMode', mode);
    notifyListeners();
  }
  
  Future<void> setPageDragSensitivity(double value) async {
    _pageDragSensitivity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pageDragSensitivity', value);
    notifyListeners();
  }
  
  Future<void> setMinFlingVelocity(double value) async {
    _minFlingVelocity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minFlingVelocity', value);
    notifyListeners();
  }
  
  // تغيير حجم الخط
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }
  
  // تغيير نوع الخط
  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
    notifyListeners();
  }

  
  // Aliases for UI compatibility
  void toggleTheme() => toggleDarkMode();
  void updateFontSize(double val) => setFontSize(val);
  
  Future<void> updateDefaultReciter(String val) async {
    _defaultReciter = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultReciter', val);
    notifyListeners();
  }
  
  Future<void> updateDefaultTafsir(String val) async {
    _defaultTafsir = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultTafsir', val);
    notifyListeners();
  }
  
  Future<void> toggleDownloadWhilePlaying() async {
    _downloadWhilePlaying = !_downloadWhilePlaying;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloadWhilePlaying', _downloadWhilePlaying);
    notifyListeners();
  }
  Future<void> setLastPage(int page) async {
    if (page == _lastPage) return;
    _lastPage = page;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPage', page);
    // Don't notify here to avoid constant rebuilds on every flip, 
    // or notify if you want other screens (like Index) to update.
  }
}