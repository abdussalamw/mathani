import 'package:flutter/foundation.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/core/di/service_locator.dart';
import 'package:fpdart/fpdart.dart'; // Added for Either
import 'package:mathani/core/errors/failures.dart'; // Added for Failure

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

  // Search State
  List<Ayah> _searchResults = [];
  List<Ayah> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final result = await _repository.searchAyahs(query);
    
    result.fold(
      (failure) {
        _searchResults = []; // Quietly fail or showing empty results
      },
      (ayahs) {
        _searchResults = ayahs;
      },
    );

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
  
  // Reading State (Synced with Mushaf View)
  int _readingSurah = 1;
  int _readingAyah = 1;
  int _readingPage = 1; // Added page tracking for Tafsir sync
  int get readingSurah => _readingSurah;
  int get readingAyah => _readingAyah;
  int get readingPage => _readingPage;

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

  // helper to get single ayah text (Uthmanic)
  Future<String?> getAyahText(int surahNumber, int ayahNumber) async {
    final result = await _repository.getAyah(surahNumber, ayahNumber);
    return result.fold(
      (failure) => null,
      (ayah) => ayah?.textUthmani ?? ayah?.text // Prefer Uthmani, fallback to simple
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

  void updateReadingLocation(int surah, int ayah) {
    if (_readingSurah != surah || _readingAyah != ayah) {
      _readingSurah = surah;
      _readingAyah = ayah;
      notifyListeners();
    }
  }

  // تحديث للتنقل
  void setJumpToSurah(int surahNumber) {
    loadSurah(surahNumber);
  }

  // تحديث الصفحة الحالية للتفسير
  void updateReadingPage(int page) {
    if (_readingPage != page) {
      _readingPage = page;
      notifyListeners(); // This allows TafsirScreen to rebuild if needed
    }
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

  // Wrapper for Repository getAyah (needed for sync logic)
  Future<Either<Failure, Ayah?>> getAyah(int surahNumber, int ayahNumber) async {
    return _repository.getAyah(surahNumber, ayahNumber);
  }

  // Dynamic Ayah Range Loading
  Future<List<Ayah>> getAyahsByRange(int startSurah, int startAyah, int endSurah, int endAyah) async {
    final result = await _repository.getAyahsCountRange(startSurah, startAyah, endSurah, endAyah);
    return result.fold(
      (l) {
        debugPrint('Error loading range ayahs: ${l.message}');
        return [];
      },
      (r) => r
    );
  }
}