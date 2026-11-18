import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mathani/data/services/digital_khatt_page_loader.dart';

void main() {
  late Directory cacheDirectory;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp(
      'digital-khatt-pages-',
    );
  });

  tearDown(() async {
    await cacheDirectory.delete(recursive: true);
  });

  test('requests the selected page and reuses its local cache', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      expect(request.url.host, 'mushafcatalog.digitalkhatt.org');
      expect(request.url.path, '/api/page.svg');
      expect(request.url.queryParameters, {
        'page': '1',
        'interior': '1',
        'kashida': 'middle',
      });
      return http.Response(_pageSvg(1), HttpStatus.ok);
    });
    final loader = DigitalKhattPageLoader(
      client: client,
      cacheDirectory: cacheDirectory,
    );

    expect(await loader.loadPage(1), _pageSvg(1));
    expect(await loader.loadPage(1), _pageSvg(1));
    expect(requestCount, 1);
    expect(File('${cacheDirectory.path}/page001.svg').existsSync(), isTrue);
    client.close();
  });

  test('rejects page numbers outside the 604-page edition', () async {
    final client = MockClient((_) async {
      fail('An invalid page must not be requested.');
    });
    final loader = DigitalKhattPageLoader(
      client: client,
      cacheDirectory: cacheDirectory,
    );

    await expectLater(loader.loadPage(605), throwsRangeError);
    client.close();
  });

  test('rejects unsuccessful or malformed page responses', () async {
    final client = MockClient((_) async {
      return http.Response('not an SVG', HttpStatus.ok);
    });
    final loader = DigitalKhattPageLoader(
      client: client,
      cacheDirectory: cacheDirectory,
    );

    await expectLater(loader.loadPage(2), throwsFormatException);
    client.close();
  });

  test('limits the local cache to twelve pages', () async {
    final client = MockClient((request) async {
      final page = int.parse(request.url.queryParameters['page']!);
      return http.Response(_pageSvg(page), HttpStatus.ok);
    });
    final loader = DigitalKhattPageLoader(
      client: client,
      cacheDirectory: cacheDirectory,
    );

    for (var page = 1; page <= 13; page++) {
      await loader.loadPage(page);
    }

    final cachedPages = await cacheDirectory
        .list()
        .where((entity) => entity.path.endsWith('.svg'))
        .length;
    expect(cachedPages, 12);
    client.close();
  });

  test('surfaces HTTP failures instead of caching an error response', () async {
    final client = MockClient(
      (_) async =>
          http.Response('service unavailable', HttpStatus.serviceUnavailable),
    );
    final loader = DigitalKhattPageLoader(
      client: client,
      cacheDirectory: cacheDirectory,
    );

    await expectLater(loader.loadPage(4), throwsA(isA<HttpException>()));
    expect(File('${cacheDirectory.path}/page004.svg').existsSync(), isFalse);
    client.close();
  });
}

String _pageSvg(int page) {
  final paddedPage = page.toString().padLeft(3, '0');
  return '<svg data-page="page$paddedPage"><path d="M0 0h1v1z"/></svg>';
}
