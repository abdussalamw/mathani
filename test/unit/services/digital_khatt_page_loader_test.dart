import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/data/services/digital_khatt_page_loader.dart';

class _Bundle extends CachingAssetBundle {
  var loads = 0;
  var fail = false;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(
      key,
      anyOf(
        DigitalKhattPageLoader.layoutAsset1441,
        DigitalKhattPageLoader.layoutAssetOldMadina,
      ),
    );
    loads++;
    if (fail) throw StateError('asset error');
    return File(key).readAsString();
  }

  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

void main() {
  test('shares one offline layout and retries a failed asset read', () async {
    final bundle = _Bundle()..fail = true;
    final loader = DigitalKhattPageLoader(bundle: bundle);
    await expectLater(loader.loadPage(1), throwsStateError);
    bundle.fail = false;
    final pages = await Future.wait([loader.loadPage(1), loader.loadPage(604)]);
    expect(bundle.loads, 2);
    expect(pages.first.length, 8);
    expect(pages.last.length, 15);
    expect(pages.last.last.runs.last.ayah, 6);
    await expectLater(loader.loadPage(605), throwsRangeError);
  });

  test(
    'each word and verse ending is on its original QCF4 page and line',
    () async {
      final bundle = _Bundle();
      final loader = DigitalKhattPageLoader(bundle: bundle);
      final reference = jsonDecode(
        await File('sorse/quran_fonts_qfc4/quran_glyphs.json').readAsString(),
      ) as List;
      final ending = RegExp(r'^۝[٠-٩]+$');
      int words = 0, endings = 0, headers = 0, basmalas = 0;
      for (final page in reference) {
        final lines = await loader.loadPage(page['page']);
        final original = page['lines'] as List;
        expect(lines.length, original.length);
        for (var i = 0; i < lines.length; i++) {
          final expected = [
            for (final g in original[i]['glyphs'])
              if (g['type'] == 1 ||
                  g['type'] == 2 ||
                  g['type'] == 6 ||
                  g['type'] == 8)
                (g['surah'] as int, (g['ayah'] ?? 0) as int, g['type'] as int),
          ];
          final actual = <(int, int, int)>[];
          for (final run in lines[i].runs) {
            if (run.ayah == 0) {
              final header = run.text.startsWith('سُورَةُ ');
              if (header) {
                headers++;
              } else {
                basmalas++;
              }
              actual.add((run.surah, 0, header ? 6 : 8));
            } else {
              for (final word in run.text.split(' ')) {
                final isEnd = ending.hasMatch(word);
                if (isEnd) {
                  final digits = word
                      .substring(1)
                      .codeUnits
                      .map((c) => c - 0x660)
                      .join();
                  expect(int.parse(digits), run.ayah);
                  endings++;
                } else {
                  words++;
                }
                actual.add((run.surah, run.ayah, isEnd ? 2 : 1));
              }
            }
          }
          expect(
            actual,
            expected,
            reason: 'page ${page['page']}, line ${i + 1}',
          );
        }
      }
      expect([words, endings, headers, basmalas], [77433, 6236, 114, 112]);
      expect(bundle.loads, 1);
    },
  );

  test(
    'Old Madina 1995 loader verifies all 604 pages, 6236 verses, headers and basmalas',
    () async {
      final bundle = _Bundle();
      final loader = DigitalKhattPageLoader(
        bundle: bundle,
        layoutAsset: DigitalKhattPageLoader.layoutAssetOldMadina,
      );
      final p1 = await loader.loadPage(1);
      final p2 = await loader.loadPage(2);
      final p3 = await loader.loadPage(3);
      final p604 = await loader.loadPage(604);

      expect(p1.length, 8);
      expect(p2.length, 8);
      expect(p3.length, 15);
      expect(p604.length, 15);

      final ending = RegExp(r'^۝[٠-٩]+$');
      int endings = 0, headers = 0, basmalas = 0;

      for (var p = 1; p <= 604; p++) {
        final lines = await loader.loadPage(p);
        expect(lines.length, (p <= 2) ? 8 : 15);
        for (final line in lines) {
          for (final run in line.runs) {
            if (run.ayah == 0) {
              if (run.text.startsWith('سُورَةُ ')) {
                headers++;
              } else {
                basmalas++;
              }
            } else {
              for (final word in run.text.split(' ')) {
                if (ending.hasMatch(word)) {
                  endings++;
                }
              }
            }
          }
        }
      }

      expect(endings, 6236);
      expect(headers, 114);
      expect(basmalas, 112);
      expect(bundle.loads, 1);
    },
  );
}
