
import 'package:flutter/foundation.dart';

class WordContent {
  final int suraNumber;
  final String suraName;
  final int ayaNumber;
  final int wordNumber;
  final String word;
  final String content;

  WordContent({
    required this.suraNumber,
    required this.suraName,
    required this.ayaNumber,
    required this.wordNumber,
    required this.word,
    required this.content,
  });

  factory WordContent.fromJson(Map<String, dynamic> json) {
    return WordContent(
      suraNumber: json['sura_number'] as int? ?? 0,
      suraName: json['sura_name'] as String? ?? '',
      ayaNumber: json['aya_number'] as int? ?? 0,
      wordNumber: json['word_number'] as int? ?? 0,
      word: json['word'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
