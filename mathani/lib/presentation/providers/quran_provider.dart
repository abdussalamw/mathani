import 'package:flutter/foundation.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/domain/repositories/audio_repository.dart';
import 'package:mathani/core/di/service_locator.dart';

class QuranProvider with ChangeNotifier {
  final QuranRepository _repository;
  final AudioRepository _audioRepository;
  
  // الحالة
  List<Surah> _surahs = [];
  List<Ayah> _currentAyahs = [];
  Surah? _currentSurah;
  
  // Audio State
  int? _playingAyahId; 
  bool _isPlaying = false;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Surah> get surahs => _surahs;
  List<Ayah> get currentAyahs => _currentAyahs;
  Surah? get currentSurah => _currentSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get playingAyahId => _playingAyahId;
  bool get isPlaying => _isPlaying;
  
  QuranProvider({QuranRepository? repository, AudioRepository? audioRepository})
      : _repository = repository ?? sl<QuranRepository>(),
        _audioRepository = audioRepository ?? sl<AudioRepository>(); 
  
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
  
  // الصوتيات
  Future<void> playAyah(int surahNumber, int ayahNumber) async {
    try {
      _playingAyahId = ayahNumber;
      _isPlaying = true;
      notifyListeners();
      
      await _audioRepository.playAyah(surahNumber, ayahNumber);
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      _playingAyahId = null;
      notifyListeners();
    }
  }
  
  Future<void> stopAudio() async {
    await _audioRepository.stop();
    _isPlaying = false;
    _playingAyahId = null;
    notifyListeners();
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
}