
import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/usecases/get_all_surahs_usecase.dart';
import '../../domain/usecases/get_ayahs_usecase.dart';
import '../../domain/entities/surah.dart';
import '../../domain/entities/ayah.dart';

class QuranProvider extends ChangeNotifier {
  // UseCases Injected from ServiceLocator
  final GetAllSurahsUseCase _getAllSurahsUseCase = sl<GetAllSurahsUseCase>();
  final GetAllAyahsUseCase _getAllAyahsUseCase = sl<GetAllAyahsUseCase>();
  final GetAyahsForSurahUseCase _getAyahsForSurahUseCase = sl<GetAyahsForSurahUseCase>();
  final GetAyahsForPageUseCase _getAyahsForPageUseCase = sl<GetAyahsForPageUseCase>();

  List<Surah> _surahs = [];
  List<Surah> get surahs => _surahs;
  List<Surah> get mappedSurahs => _surahs; 
  
  List<Ayah> _allAyahs = [];
  List<Ayah> get ayahs => _allAyahs;
  
  Map<int, List<Ayah>> _ayahsBySurah = {};
  Map<int, List<Ayah>> get ayahsBySurah => _ayahsBySurah;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _jumpToSurahNumber;
  int? get jumpToSurahNumber => _jumpToSurahNumber;

  void setJumpToSurah(int number) {
    _jumpToSurahNumber = number;
    notifyListeners();
  }

  void clearJump() {
    _jumpToSurahNumber = null;
  }

  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getAllSurahsUseCase();
    result.fold(
      (failure) {
        _errorMessage = failure.message; // or map failure type
        debugPrint('Error loading surahs: ${_errorMessage}');
      },
      (surahs) {
        _surahs = surahs;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFullQuran() async {
    if (_allAyahs.isNotEmpty && _surahs.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Ensure Surahs
    if (_surahs.isEmpty) {
      final surahResult = await _getAllSurahsUseCase();
      surahResult.fold(
        (failure) => _errorMessage = failure.message,
        (data) => _surahs = data,
      );
    }

    if (_errorMessage != null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 2. Load Ayahs
    final ayahsResult = await _getAllAyahsUseCase();
    ayahsResult.fold(
      (failure) => _errorMessage = failure.message,
      (data) {
        _allAyahs = data;
        _ayahsBySurah = {};
        for (var ayah in _allAyahs) {
          if (!_ayahsBySurah.containsKey(ayah.surahNumber)) {
            _ayahsBySurah[ayah.surahNumber] = [];
          }
          _ayahsBySurah[ayah.surahNumber]!.add(ayah);
        }
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    if (_ayahsBySurah.containsKey(surahNumber)) {
      return _ayahsBySurah[surahNumber]!;
    }
    
    final result = await _getAyahsForSurahUseCase(surahNumber);
    return result.fold(
      (failure) => [], // Return empty list on error for now
      (data) => data,
    );
  }
  
  Future<List<Ayah>> getAyahsForPage(int pageNumber) async {
    if (_allAyahs.isNotEmpty) {
      return _allAyahs.where((a) => a.page == pageNumber).toList();
    }
    
    final result = await _getAyahsForPageUseCase(pageNumber);
    return result.fold(
      (failure) => [],
      (data) => data,
    );
  }
}
