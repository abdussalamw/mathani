import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/surah_app/aya_content.dart';
import '../models/surah_app/word_content.dart';

class SurahAppApiService {
  static const String _baseUrl = 'https://dev.surahapp.com/api/v1';

  // Available Slugs from Docs
  static const List<String> tafsirSlugs = [
    'tafsir-katheer', // Ibn Kathir
    'tafsir-saadi', // Saadi
    'tafsir-baghawy', // Baghawy
    'tafsir-tabary', // Tabary
    'eerab-aya', // Eerab (Syntax)
    'ayat-nozool', // Asbab Nozool
  ];

  static const List<String> wordSlugs = [
    'meaning-word', // Word Meaning
    'eerab-word', // Word Syntax
  ];

  /// Fetch Content for a specific Ayah
  Future<AyaContent?> getAyaContent({
    required int suraNumber,
    required int ayaNumber,
    String slug = 'tafsir-katheer',
  }) async {
    final url = Uri.parse('$_baseUrl/aya/$slug/$suraNumber/$ayaNumber');
    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AyaContent.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Fetch Content for a specific Word
  Future<WordContent?> getWordContent({
    required int suraNumber,
    required int ayaNumber,
    required int wordNumber,
    String slug = 'meaning-word',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/word/$slug/$suraNumber/$ayaNumber/$wordNumber',
    );
    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WordContent.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Fetch Content for ALL words in an Ayah (Helper)
  Future<List<WordContent>> getAyahWordsContent({
    required int suraNumber,
    required int ayaNumber,
    required int wordCount,
    String slug = 'meaning-word',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/word/$slug/$suraNumber/$ayaNumber/1/$wordCount',
    );

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => WordContent.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
