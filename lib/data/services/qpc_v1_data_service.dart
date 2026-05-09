import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QPCV1DataService {
  static final QPCV1DataService _instance = QPCV1DataService._internal();
  factory QPCV1DataService() => _instance;
  QPCV1DataService._internal();

  Map<String, String> _glyphMap = {};
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      String jsonString;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDir.path}/mushafs/madani_old_v1/qpc_v1_glyphs.json');
        if (await localFile.exists()) {
          jsonString = await localFile.readAsString();
        } else {
          try {
            jsonString = await rootBundle.loadString('assets/data/qpc_v1_glyphs.json');
          } catch (_) {
            jsonString = '{}'; // Fallback to empty if both fail
          }
        }
      } else {
        try {
          jsonString = await rootBundle.loadString('assets/data/qpc_v1_glyphs.json');
        } catch (_) {
          jsonString = '{}';
        }
      }
      // Running map conversion in isolate to avoid UI jank
      final Map<String, dynamic> rawMap = await compute(_parseJson, jsonString);
      
      // Convert to Map<String, String> and optimize
      // The JSON structure is: "S:A:W": { "text": "GLYPH", ... }
      // We only need the "text" field.
      
      _glyphMap = await compute(_parseGlyphMap, rawMap);
      
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading QPC V1 Glyphs: $e');
    } finally {
      _isLoading = false;
    }
  }

  static Map<String, String> _parseGlyphMap(Map<String, dynamic> rawMap) {
    final Map<String, String> result = {};
    rawMap.forEach((key, value) {
      if (value is Map && value.containsKey('text')) {
        result[key] = value['text'] as String;
      }
    });
    return result;
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  String? getGlyph(int surah, int ayah, int word) {
    if (!_isLoaded) return null; // Should confirm specific loaded status
    final key = '$surah:$ayah:$word';
    return _glyphMap[key];
  }
  
  bool get isLoaded => _isLoaded;
}
