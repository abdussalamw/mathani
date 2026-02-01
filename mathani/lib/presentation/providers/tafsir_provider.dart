import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TafsirProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String _tafsirContent = '';
  int? _lastFetchedSurah;
  int? _lastFetchedAyah;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get tafsirContent => _tafsirContent;

  Future<void> fetchTafsir(int surah, int ayah, {int tafsirId = 16}) async {
    // Tafsir ID 16 is Tafsir Muyassar (Moyassar)
    if (_lastFetchedSurah == surah && _lastFetchedAyah == ayah) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/quran/tafsirs/$tafsirId?verse_key=$surah:$ayah'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tafsirs = data['tafsirs'] as List;
        if (tafsirs.isNotEmpty) {
          _tafsirContent = _stripHtml(tafsirs[0]['text']);
          _lastFetchedSurah = surah;
          _lastFetchedAyah = ayah;
        } else {
          _tafsirContent = 'لا يوجد تفسير متاح حالياً لهذه الآية.';
        }
      } else {
        _errorMessage = 'فشل الاتصال بالخادم (خطأ ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'خطأ في جلب التفسير: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _stripHtml(String htmlString) {
    // Simple HTML tag removal
    final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
