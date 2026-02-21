
import 'package:flutter/material.dart';
import '../../data/models/surah_app/aya_content.dart';
import '../../data/models/surah_app/word_content.dart';
import '../../data/services/surah_app_api_service.dart';
import '../../data/services/local_tafsir_service.dart';

class SurahContentProvider extends ChangeNotifier {
  final SurahAppApiService _apiService = SurahAppApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AyaContent? _currentAyaContent;
  AyaContent? get currentAyaContent => _currentAyaContent;

  List<WordContent> _currentAyaWords = [];
  List<WordContent> get currentAyaWords => _currentAyaWords;

  String _selectedTafsirSlug = 'w-moyassar'; // Default
  String get selectedTafsirSlug => _selectedTafsirSlug;

  // Selected Ayah for context
  int? _selectedSurah;
  int? _selectedAyah;
  int? _selectedWordCount;

  Future<void> fetchContent(int suraNumber, int ayaNumber, int wordCount) async {
    _isLoading = true;
    _selectedSurah = suraNumber;
    _selectedAyah = ayaNumber;
    _selectedWordCount = wordCount;
    
    // Clear previous
    _currentAyaContent = null;
    _currentAyaWords = [];
    notifyListeners();

    try {
      // Parallel Fetch
      final results = await Future.wait([
        _fetchAyaContentLogic(suraNumber, ayaNumber, _selectedTafsirSlug),
        _apiService.getAyahWordsContent(
          suraNumber: suraNumber, 
          ayaNumber: ayaNumber, 
          wordCount: wordCount,
          slug: 'meaning-word', 
        ),
      ]);

      _currentAyaContent = results[0] as AyaContent?;
      _currentAyaWords = results[1] as List<WordContent>;

    } catch (e) {
      debugPrint('Error fetching content: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AyaContent?> _fetchAyaContentLogic(int suraNumber, int ayaNumber, String slug) async {
     if (slug == 'w-moyassar') {
        final localText = await LocalTafsirService.instance.getTafsir(suraNumber, ayaNumber);
        if (localText != null && localText.trim().isNotEmpty) {
           return AyaContent(
             suraNumber: suraNumber,
             suraName: '', 
             ayaNumber: ayaNumber,
             ayaText: '',
             content: localText,
           );
        }
     }
     return await _apiService.getAyaContent(
       suraNumber: suraNumber,
       ayaNumber: ayaNumber,
       slug: slug,
     );
  }

  Future<String?> fetchTafsirForAyah(int suraNumber, int ayaNumber) async {
    try {
      final slug = _selectedTafsirSlug.isNotEmpty ? _selectedTafsirSlug : 'w-moyassar';
      final ayaContent = await _fetchAyaContentLogic(suraNumber, ayaNumber, slug);
      return ayaContent?.content;
    } catch (e) {
      debugPrint('Error fetching specific tafsir: $e');
      return null;
    }
  }

  Future<void> changeTafsir(String newSlug) async {
    if (_selectedTafsirSlug == newSlug) return;
    _selectedTafsirSlug = newSlug;
    notifyListeners();
    // Refetch full content if context is available
    if (_selectedSurah != null && _selectedAyah != null && _selectedWordCount != null) {
      await fetchContent(_selectedSurah!, _selectedAyah!, _selectedWordCount!);
    }
  }

  void setTafsirSlug(String slug, {bool shouldNotify = false}) {
    _selectedTafsirSlug = slug;
    if (shouldNotify) notifyListeners(); 
  }
}
