
import 'package:flutter/foundation.dart';

class AyaContent {
  final int suraNumber;
  final String suraName;
  final int ayaNumber;
  final String ayaText;
  final String content;

  AyaContent({
    required this.suraNumber,
    required this.suraName,
    required this.ayaNumber,
    required this.ayaText,
    required this.content,
  });

  factory AyaContent.fromJson(Map<String, dynamic> json) {
    return AyaContent(
      suraNumber: json['sura_number'] as int? ?? 0,
      suraName: json['sura_name'] as String? ?? '',
      ayaNumber: json['aya_number'] as int? ?? 0,
      ayaText: json['aya_text'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
