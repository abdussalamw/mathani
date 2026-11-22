import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/surah.dart';
import '../../models/ayah.dart';

class QuranLocalDataSource {
  static final QuranLocalDataSource _instance =
      QuranLocalDataSource._internal();
  static QuranLocalDataSource get instance => _instance;

  QuranLocalDataSource._internal();

  // Cache للبيانات المحملة
  Future<List<dynamic>>? _pending;
  final _byPage = <int, List<({int surah, Map<String, dynamic> verse})>>{};

  Future<List<dynamic>> _loadData() => _pending ??= _read();
  Future<List<dynamic>> _read() async {
    try {
      final json = await rootBundle.loadString(
        'assets/data/quran_advanced.json',
      );
      final rows = await compute(_decodeSurahs, json);
      for (final surah in rows) {
        for (final verse in surah['verses']) {
          _byPage.putIfAbsent(verse['page'], () => []).add((
            surah: surah['id'],
            verse: verse,
          ));
        }
      }
      return rows;
    } catch (_) {
      _pending = null;
      _byPage.clear();
      rethrow;
    }
  }

  /// جلب جميع السور
  Future<List<Surah>> loadAllSurahs() async {
    final data = await _loadData();
    final List<Surah> surahs = [];

    for (var item in data) {
      if (item is! Map<String, dynamic>) continue;

      int startPage = 1;
      if (item['verses'] != null &&
          (item['verses'] is List) &&
          (item['verses'] as List).isNotEmpty) {
        startPage = item['verses'][0]['page'] ?? 1;
      }

      surahs.add(
        Surah()
          ..number = item['id'] as int
          ..nameArabic = item['name'] as String
          ..nameEnglish = item['transliteration'] as String
          ..nameEnglishTranslation =
              item['transliteration']
                  as String // fallback
          ..numberOfAyahs = item['total_verses'] as int
          ..revelationType = item['type'] as String
          ..page = startPage,
      );
    }

    return surahs;
  }

  /// جلب آيات سورة معينة
  Future<List<Ayah>> loadAyahsForSurah(int surahNumber) async {
    final data = await _loadData();
    final List<Ayah> ayahs = [];

    // البحث عن السورة المطلوبة
    final surahData = data.firstWhere(
      (item) => item['id'] == surahNumber,
      orElse: () => null,
    );

    if (surahData != null && surahData['verses'] is List) {
      final verses = surahData['verses'] as List;

      for (var verse in verses) {
        if (verse is! Map<String, dynamic>) continue;

        ayahs.add(Ayah.fromJson(verse, surahNumber));
      }
    }

    return ayahs;
  }

  /// جلب آيات صفحة معينة
  Future<List<Ayah>> loadAyahsForPage(int pageNumber) async {
    await _loadData();
    return [
      for (final item in _byPage[pageNumber] ?? [])
        Ayah.fromJson(item.verse, item.surah),
    ];
  }

  /// جلب جميع الآيات (للبحث والتهيئة)
  Future<List<Ayah>> loadAllAyahs() async {
    final data = await _loadData();
    final List<Ayah> allAyahs = [];

    for (var surahItem in data) {
      if (surahItem is! Map<String, dynamic>) continue;
      final surahId = surahItem['id'] as int;

      if (surahItem['verses'] is List) {
        final verses = surahItem['verses'] as List;
        for (var verse in verses) {
          allAyahs.add(
            Ayah.fromJson(verse, surahId),
          ); // Uses the updated fromJson with normalization
        }
      }
    }
    return allAyahs;
  }
}

List<dynamic> _decodeSurahs(String source) =>
    jsonDecode(source) as List<dynamic>;
