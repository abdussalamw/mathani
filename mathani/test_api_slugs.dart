
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://dev.surahapp.com/api/v1/aya';
  const slugs = [
    'w-moyassar',
    'tafsir-katheer',
    'tafsir-saadi',
    'tafsir-baghawy',
    'tafsir-tabary',
    'eerab-aya',
    'ayat-nozool',
  ];

  print('Testing Tafsir Slugs on $baseUrl...');
  
  for (final slug in slugs) {
    // Test Surah 1, Ayah 1 (Al-Fatiha)
    // Note: Eerab or Nozool might not exist for EVERY ayah, but usually exist for Fatiha.
    final url = Uri.parse('$baseUrl/$slug/1/1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as String?;
        if (content != null && content.isNotEmpty) {
           print('✅ $slug: OK (${content.substring(0, 20)}...)');
        } else {
           print('⚠️ $slug: 200 OK but content empty');
        }
      } else {
        print('❌ $slug: Failed with ${response.statusCode}');
      }
    } catch (e) {
      print('❌ $slug: Error $e');
    }
  }
}
