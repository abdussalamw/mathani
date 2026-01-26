
import 'package:dio/dio.dart';

class RemoteDataSource {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<Map<String, dynamic>> fetchAllSurahs() async {
    try {
      final response = await _dio.get('$_baseUrl/surah');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load surahs list: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFullQuran() async {
    try {
      final response = await _dio.get('$_baseUrl/quran/quran-uthmani');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load full quran: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSurah(int surahNumber) async {
    try {
      final response = await _dio.get('$_baseUrl/surah/$surahNumber/quran-uthmani');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load surah: $e');
    }
  }

  Future<Map<String, dynamic>> fetchMeta() async {
    try {
      final response = await _dio.get('$_baseUrl/meta');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load meta data: $e');
    }
  }
}
