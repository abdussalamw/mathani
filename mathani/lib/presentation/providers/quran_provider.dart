import 'package:flutter/foundation.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/core/di/service_locator.dart';

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
      : _repository = repository ?? sl<QuranRepository>(); 
  
  // تحميل جميع السور
  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await _repository.getAllSurahs();
    
    result.fold(
      (failure) {
        _errorMessage = 'خطأ في تحميل السور: ${failure.message}';
        _isLoading = false;
        notifyListeners();
      },
      (surahs) {
        _surahs = surahs;
        _isLoading = false;
        notifyListeners();
      }
    );
  }
  
  // تحميل سورة وآياتها
  Future<void> loadSurah(int surahNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Parallel fetching for efficiency
    final surahResultFuture = _repository.getSurahByNumber(surahNumber);
    final ayahsResultFuture = _repository.getAyahsForSurah(surahNumber); // Corrected method name
    
    final results = await Future.wait([surahResultFuture, ayahsResultFuture]);
    
    final surahResult = results[0] as dynamic; // casting needed due to dynamic list
    final ayahsResult = results[1] as dynamic;
    
    // Check Surah Result
    surahResult.fold(
      (failure) {
         _errorMessage = 'خطأ في تحميل السورة: ${failure.message}';
         _isLoading = false;
         notifyListeners();
         return;
      },
      (surah) {
         _currentSurah = surah;
      }
    );
    
    if (_errorMessage != null) return;
    
    // Check Ayahs Result
    ayahsResult.fold(
      (failure) {
         _errorMessage = 'خطأ في تحميل الآيات: ${failure.message}';
         _isLoading = false;
         notifyListeners();
      },
      (ayahs) {
         _currentAyahs = ayahs;
         _isLoading = false;
         notifyListeners();
      }
    );
  }
  
  // تحديث آخر قراءة
  Future<void> updateLastRead(int surahNumber, int ayahNumber) async {
    final result = await _repository.updateLastRead(surahNumber, ayahNumber);
    result.fold(
      (l) => debugPrint('Error updating last read: ${l.message}'),
      (r) => notifyListeners()
    );
  }
  
  // إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(int surahNumber) async {
    final result = await _repository.toggleFavorite(surahNumber);
    result.fold(
      (l) => debugPrint('Error toggling favorite: ${l.message}'),
      (r) => loadSurahs() // إعادة تحميل للتحديث
    );
  }

  // تحديث للتنقل
  void setJumpToSurah(int surahNumber) {
    loadSurah(surahNumber);
  }

  // لجلب آيات صفحة كاملة (للمصحف الرقمي)
  Future<List<Ayah>> getAyahsForPage(int pageNumber) async {
    final result = await _repository.getAyahsForPage(pageNumber);
    return result.fold(
      (l) {
        debugPrint('Error loading page ayahs: ${l.message}');
        return [];
      },
      (r) => r
    );
  }
}