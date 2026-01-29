import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 24.0;
  String _fontFamily = 'Amiri';
  String _defaultReciter = 'minshawi_murattal';
  String _defaultTafsir = 'muyassar';
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get defaultReciter => _defaultReciter;
  String get defaultTafsir => _defaultTafsir;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 24.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Amiri';
    _defaultReciter = prefs.getString('defaultReciter') ?? 'minshawi_murattal';
    _defaultTafsir = prefs.getString('defaultTafsir') ?? 'muyassar';
    notifyListeners();
  }
  
  // تبديل الوضع الليلي
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
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
}