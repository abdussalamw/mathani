import 'package:dio/dio.dart';
import 'package:mathani/core/constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  
  Dio get dio => _dio; // Public getter for dio instance
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.alQuranCloudBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    
    // Interceptor للـ logging (اختياري)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }
  
  // جلب جميع السور
  Future<List<dynamic>> fetchAllSurahs() async {
    try {
      final response = await _dio.get(ApiConstants.surahs);
      return response.data['data'];
    } catch (e) {
      throw Exception('فشل جلب السور: $e');
    }
  }
  
  // جلب سورة معينة مع آياتها
  Future<Map<String, dynamic>> fetchSurah(int surahNumber) async {
    try {
      final response = await _dio.get('${ApiConstants.surahById}$surahNumber');
      return response.data['data'];
    } catch (e) {
      throw Exception('فشل جلب السورة رقم $surahNumber: $e');
    }
  }
  
  // جلب آيات سورة برسم عثماني
  Future<Map<String, dynamic>> fetchSurahUthmani(int surahNumber) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.surahById}$surahNumber/quran-uthmani'
      );
      return response.data['data'];
    } catch (e) {
      throw Exception('فشل جلب السورة بالرسم العثماني: $e');
    }
  }
}