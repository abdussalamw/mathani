
import 'package:flutter/material.dart';
import '../core/database/collections.dart';
import '../repositories/quran_repository.dart';

class QuranProvider extends ChangeNotifier {
  final QuranRepository _repository = QuranRepository();
  
  List<Surah> _surahs = [];
  List<Surah> get surahs => _surahs;
  List<Surah> get mappedSurahs => _surahs; // Alias for compatibility
  
  List<Ayah> _allAyahs = [];
  List<Ayah> get ayahs => _allAyahs;
  
  Map<int, List<Ayah>> _ayahsBySurah = {};
  Map<int, List<Ayah>> get ayahsBySurah => _ayahsBySurah;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Load just list of Surahs (metadata)
  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _surahs = await _repository.getAllSurahs();
    } catch (e) {
      _errorMessage = 'فشل في تحميل بيانات السور.';
      debugPrint('Error loading surahs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Full Quran (Surahs + Ayahs)
  Future<void> loadFullQuran() async {
    // If already loaded, don't reload
    if (_allAyahs.isNotEmpty && _surahs.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ensure Surahs are loaded
      if (_surahs.isEmpty) {
        _surahs = await _repository.getAllSurahs();
      }

      // 2. Load all Ayahs
      _allAyahs = await _repository.getAllAyahs();
      
      // 3. Group Ayahs by Surah
      _ayahsBySurah = {};
      for (var ayah in _allAyahs) {
        if (!_ayahsBySurah.containsKey(ayah.surahNumber)) {
          _ayahsBySurah[ayah.surahNumber] = [];
        }
        _ayahsBySurah[ayah.surahNumber]!.add(ayah);
      }
      
    } catch (e) {
      _errorMessage = 'فشل في تحميل النص القرآني الكامل.';
      debugPrint('Error loading full quran: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) {
    if (_ayahsBySurah.containsKey(surahNumber)) {
      return Future.value(_ayahsBySurah[surahNumber]);
    }
    return _repository.getAyahsForSurah(surahNumber);
  }
  
  Future<List<Ayah>> getAyahsForPage(int pageNumber) {
    // Optimization: Filter from memory if loaded
    if (_allAyahs.isNotEmpty) {
      return Future.value(_allAyahs.where((a) => a.page == pageNumber).toList());
    }
    return _repository.getAyahsForPage(pageNumber);
  }
}
