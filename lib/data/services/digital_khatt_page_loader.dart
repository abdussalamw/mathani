import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DigitalKhattPageLoader {
  DigitalKhattPageLoader({http.Client? client, Directory? cacheDirectory})
    : _client = client ?? http.Client(),
      _cacheDirectory = cacheDirectory;

  static const int pageCount = 604;
  static const int _maxCachedPages = 12;
  static const String _host = 'mushafcatalog.digitalkhatt.org';

  final http.Client _client;
  final Directory? _cacheDirectory;
  final Map<int, Future<String>> _inFlight = {};

  Future<String> loadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > pageCount) {
      throw RangeError.range(pageNumber, 1, pageCount, 'pageNumber');
    }
    if (kIsWeb) {
      throw UnsupportedError(
        'مصحف المدينة 1441 التجريبي غير متاح على الويب حاليًا.',
      );
    }

    final pending = _inFlight[pageNumber];
    if (pending != null) return pending;

    final request = _loadPage(pageNumber);
    _inFlight[pageNumber] = request;
    try {
      return await request;
    } finally {
      _inFlight.remove(pageNumber);
    }
  }

  Future<String> _loadPage(int pageNumber) async {
    final cacheDirectory = await _getCacheDirectory();
    final pageFile = File(
      '${cacheDirectory.path}/page${pageNumber.toString().padLeft(3, '0')}.svg',
    );

    if (await pageFile.exists()) {
      final cachedSvg = await pageFile.readAsString();
      if (_isValidPageSvg(cachedSvg, pageNumber)) {
        await pageFile.setLastModified(DateTime.now());
        return cachedSvg;
      }
      debugPrint('Removing invalid cached DigitalKhatt page $pageNumber.');
      await pageFile.delete();
    }

    final uri = Uri.https(_host, '/api/page.svg', {
      'page': pageNumber.toString(),
      'interior': '1',
      'kashida': 'middle',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'DigitalKhatt page request failed (${response.statusCode}).',
        uri: uri,
      );
    }

    final svg = utf8.decode(response.bodyBytes);
    if (!_isValidPageSvg(svg, pageNumber)) {
      throw FormatException(
        'The response is not a valid SVG for page $pageNumber.',
      );
    }

    await cacheDirectory.create(recursive: true);
    final temporaryFile = File(
      '${pageFile.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporaryFile.writeAsString(svg, encoding: utf8, flush: true);
      await temporaryFile.rename(pageFile.path);
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
    await _trimCache(cacheDirectory);
    return svg;
  }

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDirectory != null) return _cacheDirectory;
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory('${appDirectory.path}/mushafs/digital_khatt_1441');
  }

  bool _isValidPageSvg(String svg, int pageNumber) {
    final paddedPage = pageNumber.toString().padLeft(3, '0');
    return svg.contains('<svg') &&
        svg.contains('</svg>') &&
        svg.contains('data-page="page$paddedPage"');
  }

  Future<void> _trimCache(Directory directory) async {
    final cachedPages = <MapEntry<File, DateTime>>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !RegExp(r'^page\d{3}\.svg$').hasMatch(entity.uri.pathSegments.last)) {
        continue;
      }
      cachedPages.add(MapEntry(entity, (await entity.stat()).modified));
    }

    cachedPages.sort((a, b) => a.value.compareTo(b.value));
    while (cachedPages.length > _maxCachedPages) {
      await cachedPages.removeAt(0).key.delete();
    }
  }
}

final digitalKhattPageLoader = DigitalKhattPageLoader();
