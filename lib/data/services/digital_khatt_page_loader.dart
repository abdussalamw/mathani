import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef MadinaVerseRun = ({int surah, int ayah, String text, int firstWord});

class MadinaLine {
  const MadinaLine(this.centered, this.runs);
  final bool centered;
  final List<MadinaVerseRun> runs;
}

class DigitalKhattPageLoader {
  DigitalKhattPageLoader({
    AssetBundle? bundle,
    this.layoutAsset = layoutAsset1441,
  }) : _bundle = bundle ?? rootBundle;

  static const pageCount = 604;
  static const layoutAsset1441 = 'assets/data/digital_khatt_1441.json';
  static const layoutAssetOldMadina = 'assets/data/digital_khatt_old_madina.json';
  final AssetBundle _bundle;
  final String layoutAsset;
  List<List<MadinaLine>>? _pages;
  Future<List<List<MadinaLine>>>? _loading;

  Future<List<MadinaLine>> loadPage(int page) async {
    RangeError.checkValueInInterval(page, 1, pageCount, 'page');
    final pages = _pages ?? await (_loading ??= _load());
    return pages[page - 1];
  }

  Future<List<List<MadinaLine>>> _load() async {
    try {
      final json = await _bundle.loadString(layoutAsset, cache: false);
      final pages = await compute(_decodePages, json);
      _pages = pages;
      return pages;
    } finally {
      _loading = null;
    }
  }
}

List<List<MadinaLine>> _decodePages(String json) {
  final pages = jsonDecode(json) as List;
  if (pages.length != DigitalKhattPageLoader.pageCount) {
    throw const FormatException('ملف أسطر مصحف المدينة غير مكتمل');
  }
  final wordCounts = <(int, int), int>{};
  MadinaVerseRun decodeRun(List<dynamic> run) {
    final surah = run[0] as int;
    final ayah = run[1] as int;
    final text = run[2] as String;
    final key = (surah, ayah);
    final firstWord = ayah == 0 ? 0 : (wordCounts[key] ?? 0) + 1;
    if (ayah != 0) {
      final count = text
          .split(' ')
          .where((word) => !word.startsWith('۝'))
          .length;
      wordCounts[key] = firstWord + count - 1;
    }
    return (surah: surah, ayah: ayah, text: text, firstWord: firstWord);
  }

  return [
    for (final lines in pages)
      [
        for (final line in lines)
          MadinaLine(line[0] as bool, [
            for (final run in line[1]) decodeRun(run as List<dynamic>),
          ]),
      ],
  ];
}

final digitalKhattPageLoader = DigitalKhattPageLoader();
final digitalKhattOldMadinaLoader = DigitalKhattPageLoader(
  layoutAsset: DigitalKhattPageLoader.layoutAssetOldMadina,
);
