import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 24.0;
  String _fontFamily = 'Amiri';
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 24.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Amiri';
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
}