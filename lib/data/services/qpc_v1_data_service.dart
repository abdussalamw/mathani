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
  Future<void>? _loadingFuture;

  int _generation = 0;

  void invalidate() {
    _generation++;
    _glyphMap = {};
    _isLoaded = false;
    _loadingFuture = null;
  }

  Future<void> load() async {
    if (_isLoaded && _glyphMap.isNotEmpty) return;
    if (_loadingFuture != null) return _loadingFuture;

    final pending = _loadingFuture = _loadInternal(_generation);
    try {
      await pending;
    } finally {
      if (identical(_loadingFuture, pending)) _loadingFuture = null;
    }
  }

  Future<void> _loadInternal(int generation) async {
    try {
      String jsonString;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File(
          '${appDir.path}/mushafs/madani_old_v1/qpc_v1_glyphs.json',
        );
        if (await localFile.exists()) {
          jsonString = await localFile.readAsString();
        } else {
          try {
            jsonString = await rootBundle.loadString(
              'assets/data/qpc_v1_glyphs.json',
            );
          } catch (_) {
            jsonString = '{}'; // Fallback to empty if both fail
          }
        }
      } else {
        try {
          jsonString = await rootBundle.loadString(
            'assets/data/qpc_v1_glyphs.json',
          );
        } catch (_) {
          jsonString = '{}';
        }
      }
      // Running map conversion in isolate to avoid UI jank
      final Map<String, dynamic> rawMap = await compute(_parseJson, jsonString);

      // Convert to Map<String, String> and optimize
      // The JSON structure is: "S:A:W": { "text": "GLYPH", ... }
      // We only need the "text" field.

      final parsed = await compute(_parseGlyphMap, rawMap);
      if (generation != _generation) return;
      if (parsed.isNotEmpty) {
        _glyphMap = parsed;
        _isLoaded = true;
      } else {
        _isLoaded = false;
      }
    } catch (e) {
      if (generation != _generation) return;
      debugPrint('Error loading QPC V1 Glyphs: $e');
      _isLoaded = false;
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
