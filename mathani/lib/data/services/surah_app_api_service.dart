
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah_app/aya_content.dart';
import '../models/surah_app/word_content.dart';

class SurahAppApiService {
  static const String _baseUrl = 'https://dev.surahapp.com/api/v1';

  // Available Slugs from Docs
  static const List<String> tafsirSlugs = [
    'tafsir-katheer', // Ibn Kathir
    'w-moyassar',     // Moyassar
    'tafsir-saadi',   // Saadi
    'tafsir-baghawy', // Baghawy
    'tafsir-tabary',  // Tabary
    'eerab-aya',      // Eerab (Syntax)
    'ayat-nozool',    // Asbab Nozool
  ];

  static const List<String> wordSlugs = [
    'meaning-word',   // Word Meaning
    'eerab-word',     // Word Syntax
  ];

  /// Fetch Content for a specific Ayah
  Future<AyaContent?> getAyaContent({
    required int suraNumber,
    required int ayaNumber,
    String slug = 'w-moyassar',
  }) async {
    final url = Uri.parse('$_baseUrl/aya/$slug/$suraNumber/$ayaNumber');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AyaContent.fromJson(data);
      } else {
        // Handle 404 or other errors
        return null;
      }
    } catch (e) {
      // Handle network errors
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
    final url = Uri.parse('$_baseUrl/word/$slug/$suraNumber/$ayaNumber/$wordNumber');
    try {
      final response = await http.get(url);
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
  /// Note: The API supports ranges, but words in an ayah are usually 1..N
  /// We might need to know how many words are there first, or just try fetching until 404?
  /// Better approach: The API supports ranges! /word/{slug}/{sura}/{aya}/{from}/{to}
  /// But we don't know 'to'. 
  /// However, we can use the 'Page' or 'Aya' endpoint if it returns words? No.
  /// Text-based Mushaf knows token count. We can pass it from the UI.
  Future<List<WordContent>> getAyahWordsContent({
    required int suraNumber,
    required int ayaNumber,
    required int wordCount,
    String slug = 'meaning-word',
  }) async {
    // Determine range: 1 to wordCount
    // Endpoint: /word/{slug}/{sura}/{aya}/{from}/{to}
    final url = Uri.parse('$_baseUrl/word/$slug/$suraNumber/$ayaNumber/1/$wordCount');
    
    try {
      final response = await http.get(url);
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
