import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 24.0;
  String _fontFamily = 'Amiri';
  String _defaultReciter = 'Minshawi_Murattal_128kbps';
  String _defaultTafsir = 'w-moyassar';
  bool _downloadWhilePlaying = true;
  String _backgroundColorMode = 'white'; // white, cream, old

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get defaultReciter => _defaultReciter;
  String get defaultTafsir => _defaultTafsir;
  bool get downloadWhilePlaying => _downloadWhilePlaying;
  String get backgroundColorMode => _backgroundColorMode;

  Color get backgroundColor {
    if (_isDarkMode) return const Color(0xFF1A1A1A);
    switch (_backgroundColorMode) {
      case 'cream': return const Color(0xFFFFFBF0); // Values confirmed by user
      case 'old': return const Color(0xFFF3E5AB);
      case 'white': 
      default: return Colors.white;
    }
  }

  // --- Actions ---

  SettingsProvider() {
    _loadSettings();
  }
  
  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _backgroundColorMode = prefs.getString('backgroundColorMode') ?? 'white';
    _fontSize = prefs.getDouble('fontSize') ?? 24.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Amiri';
    _defaultReciter = prefs.getString('defaultReciter') ?? 'Minshawi_Murattal_128kbps';
    _defaultTafsir = prefs.getString('defaultTafsir') ?? 'w-moyassar';
    _downloadWhilePlaying = prefs.getBool('downloadWhilePlaying') ?? true;
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
}