
import 'package:flutter/material.dart';
import '../core/database/collections.dart';
import '../repositories/quran_repository.dart';

class QuranProvider extends ChangeNotifier {
  final QuranRepository _repository = QuranRepository();
  
  List<Surah> _surahs = [];
  List<Surah> get surahs => _surahs;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Initialize data
  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _surahs = await _repository.getAllSurahs();
    } catch (e) {
      _errorMessage = 'فشل في تحميل المصحف. يرجى التحقق من الإنترنت للمرة الأولى.';
      debugPrint('Error loading surahs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) {
    return _repository.getAyahsForSurah(surahNumber);
  }
  
  Future<List<Ayah>> getAyahsForPage(int pageNumber) {
    return _repository.getAyahsForPage(pageNumber);
  }
}
