import 'package:material_ui/material_ui.dart';

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

  String _selectedTafsirSlug = 'muyassar'; // Default
  String get selectedTafsirSlug => _selectedTafsirSlug;

  // Selected Ayah for context
  int? _selectedSurah;
  int? _selectedAyah;
  int? _selectedWordCount;
  int _requestGeneration = 0;

  Future<void> fetchContent(
    int suraNumber,
    int ayaNumber,
    int wordCount,
  ) async {
    final currentGen = ++_requestGeneration;
    _isLoading = true;
    _selectedSurah = suraNumber;
    _selectedAyah = ayaNumber;
    _selectedWordCount = wordCount;

    // Clear previous
    _currentAyaContent = null;
    _currentAyaWords = [];
    notifyListeners();

    try {
      // 1. Fetch Tafsir (local finishes immediately)
      final tafsirFuture = _fetchAyaContentLogic(
        suraNumber,
        ayaNumber,
        _selectedTafsirSlug,
      );

      // If local tafsir finishes fast, display it without waiting for words API
      tafsirFuture.then((content) {
        if (currentGen == _requestGeneration) {
          _currentAyaContent = content;
          _isLoading = false;
          notifyListeners();
        }
      });

      // 2. Fetch word-by-word content without blocking tafsir
      try {
        final words = await _apiService.getAyahWordsContent(
          suraNumber: suraNumber,
          ayaNumber: ayaNumber,
          wordCount: wordCount,
          slug: 'meaning-word',
        );
        if (currentGen == _requestGeneration) {
          _currentAyaWords = words;
          notifyListeners();
        }
      } catch (_) {}

      final finalContent = await tafsirFuture;
      if (currentGen == _requestGeneration) {
        _currentAyaContent = finalContent;
      }
    } catch (e) {
      debugPrint('Error fetching content: $e');
    } finally {
      if (currentGen == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<AyaContent?> _fetchAyaContentLogic(
    int suraNumber,
    int ayaNumber,
    String slug,
  ) async {
    // Migrate old identifier to new one for local tafsir
    if (slug == 'muyassar' || slug == 'w-moyassar') {
      final localText = await LocalTafsirService.instance.getTafsir(
        suraNumber,
        ayaNumber,
      );
      if (localText != null && localText.trim().isNotEmpty) {
        return AyaContent(
          suraNumber: suraNumber,
          suraName: '',
          ayaNumber: ayaNumber,
          ayaText: '',
          content: localText,
        );
      }
      // User requested: No internet fallback for Muyassar.
      // If not local, it stays null.
      return null;
    }

    // Other tafsirs still use the API
    return await _apiService.getAyaContent(
      suraNumber: suraNumber,
      ayaNumber: ayaNumber,
      slug: slug,
    );
  }

  Future<String?> fetchTafsirForAyah(int suraNumber, int ayaNumber) async {
    try {
      final slug = _selectedTafsirSlug.isNotEmpty
          ? _selectedTafsirSlug
          : 'muyassar';
      final ayaContent = await _fetchAyaContentLogic(
        suraNumber,
        ayaNumber,
        slug,
      );
      return ayaContent?.content;
    } catch (e) {
      debugPrint('Error fetching specific tafsir: $e');
      return null;
    }
  }

  Future<void> changeTafsir(String newSlug) async {
    if (newSlug == 'muyassar') newSlug = 'muyassar';
    if (_selectedTafsirSlug == newSlug) return;
    _selectedTafsirSlug = newSlug;
    notifyListeners();
    // Refetch full content if context is available
    if (_selectedSurah != null &&
        _selectedAyah != null &&
        _selectedWordCount != null) {
      await fetchContent(_selectedSurah!, _selectedAyah!, _selectedWordCount!);
    }
  }

  void setTafsirSlug(String slug, {bool shouldNotify = false}) {
    _selectedTafsirSlug = slug;
    if (shouldNotify) notifyListeners();
  }
}
