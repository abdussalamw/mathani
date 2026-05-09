
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class QuranRemoteDataSource {
  final ApiClient _client = ApiClient();
  // Base URL is handled in ApiClient now

  Future<Map<String, dynamic>> fetchAllSurahs() async {
    try {
      final response = await _client.dio.get('/surah');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load surahs list: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFullQuran() async {
    try {
      final response = await _client.dio.get('/quran/quran-uthmani');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load full quran: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSurah(int surahNumber) async {
    try {
      final response = await _client.dio.get('/surah/$surahNumber/quran-uthmani');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load surah: $e');
    }
  }

  Future<Map<String, dynamic>> fetchMeta() async {
    try {
      final response = await _client.dio.get('/meta');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load meta data: $e');
    }
  }
}
