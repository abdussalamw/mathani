
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  double _fontSize = 28.0;
  double get fontSize => _fontSize;
  
  String _defaultReciter = 'minshawi_murattal';
  String get defaultReciter => _defaultReciter;
  
  String _defaultTafsir = 'muyassar';
  String get defaultTafsir => _defaultTafsir;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }
  
  void updateDefaultReciter(String reciterId) {
    _defaultReciter = reciterId;
    notifyListeners();
  }
  
  void updateDefaultTafsir(String tafsirId) {
    _defaultTafsir = tafsirId;
    notifyListeners();
  }
}
