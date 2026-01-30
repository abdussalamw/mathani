import 'dart:convert';
import 'package:flutter/services.dart';

class MetadataLocalDataSource {
  Future<Map<String, dynamic>> loadQuranMetadata() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran_metadata.json');
      return json.decode(jsonString);
    } catch (e) {
      throw Exception('Failed to load metadata: $e');
    }
  }
}
