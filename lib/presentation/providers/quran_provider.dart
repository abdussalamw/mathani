import 'package:flutter/foundation.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/data/repositories/quran_repository.dart';

class QuranProvider with ChangeNotifier {
  final QuranRepository _repository;
  
  // الحالة
  List<Surah> _surahs = [];
  List<Ayah> _currentAyahs = [];
  Surah? _currentSurah;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Surah> get surahs => _surahs;
  List<Ayah> get currentAyahs => _currentAyahs;
  Surah? get currentSurah => _currentSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  QuranProvider({QuranRepository? repository})
      : _repository = repository ?? QuranRepository();
  
  // تحميل جميع السور
  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _surahs = await _repository.getAllSurahs();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'خطأ في تحميل السور: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // تحميل سورة وآياتها
  Future<void> loadSurah(int surahNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentSurah = await _repository.getSurahByNumber(surahNumber);
      _currentAyahs = await _repository.getAyahsOfSurah(surahNumber);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'خطأ في تحميل السورة: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // تحديث آخر قراءة
  Future<void> updateLastRead(int surahNumber, int ayahNumber) async {
    await _repository.updateLastRead(surahNumber, ayahNumber);
    notifyListeners();
  }
  
  // إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(int surahNumber) async {
    await _repository.toggleFavorite(surahNumber);
    await loadSurahs(); // إعادة تحميل للتحديث
  }
}