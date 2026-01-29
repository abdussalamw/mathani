import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../domain/entities/user_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final GetSettingsUseCase _getSettingsUseCase = sl<GetSettingsUseCase>();
  final SaveSettingsUseCase _saveSettingsUseCase = sl<SaveSettingsUseCase>();

  // Default values
  bool _isDarkMode = false;
  double _fontSize = 28.0;
  String _defaultReciter = 'minshawi_murattal';
  String _defaultTafsir = 'muyassar';
  String _selectedMushafId = 'madani_font_v1';

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get defaultReciter => _defaultReciter;
  String get defaultTafsir => _defaultTafsir;
  String get selectedMushafId => _selectedMushafId;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await _getSettingsUseCase();
    result.fold(
      (failure) => debugPrint('Error loading settings: ${failure.message}'),
      (settings) {
        _isDarkMode = settings.isDarkMode;
        _fontSize = settings.fontSize;
        _defaultReciter = settings.defaultReciterId;
        _defaultTafsir = settings.defaultTafsirId;
        _selectedMushafId = settings.selectedMushafId;
        notifyListeners();
      },
    );
  }

  Future<void> _save() async {
    final settings = UserSettings(
      isDarkMode: _isDarkMode,
      fontSize: _fontSize,
      selectedMushafId: _selectedMushafId,
      defaultReciterId: _defaultReciter,
      defaultTafsirId: _defaultTafsir,
    );
    
    await _saveSettingsUseCase(settings);
    // No verify needed usually, UI updates optimistically or we reload
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _save();
  }

  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
    _save();
  }
  
  void updateDefaultReciter(String reciterId) {
    _defaultReciter = reciterId;
    notifyListeners();
    _save();
  }

  void updateDefaultTafsir(String tafsirId) {
    _defaultTafsir = tafsirId;
    notifyListeners();
    _save();
  }
  
  // Called by MushafMetadataProvider or directly
  Future<void> updateSelectedMushaf(String mushafId) async {
    _selectedMushafId = mushafId;
    notifyListeners();
    await _save();
  }
}
