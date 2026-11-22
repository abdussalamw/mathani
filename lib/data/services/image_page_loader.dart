import 'dart:ui' as ui;

import 'mushaf_package.dart';
import '../../core/utils/async_work_pool.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImagePageLoader {
  static Future<String> getLocalPath(String mushafId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final path = '${appDir.path}/mushafs/$mushafId';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  static final _work = AsyncWorkPool<(String, int, String, String), File?>();
  static Future<bool> _valid(Uint8List bytes) async {
    if (!imageHeaderValid(bytes, bytes.length)) return false;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        return true;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<File?> getPageImage(
    String mushafId,
    int pageNumber,
    String baseUrl, {
    String extension = 'jpg',
  }) => _work.run((
    mushafId,
    pageNumber,
    baseUrl,
    extension,
  ), () => _load(mushafId, pageNumber, baseUrl, extension));

  static Future<File?> _load(
    String mushafId,
    int pageNumber,
    String baseUrl,
    String extension,
  ) async {
    try {
      final localDir = await getLocalPath(mushafId);
      final padPage = pageNumber.toString().padLeft(3, '0');

      // 1. Check ALL possible local extensions first
      final supportedExtensions = ['webp', 'png', 'jpg'];
      for (var ext in supportedExtensions) {
        for (final candidate in [
          File('$localDir/$padPage.$ext'),
          File('$localDir/$pageNumber.$ext'),
          File('$localDir/page_$padPage.$ext'),
        ]) {
          if (await candidate.exists() &&
              await _valid(await candidate.readAsBytes())) {
            return candidate;
          }
        }
      }

      // 2. Download if not exists
      String baseUrlFormatted = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

      final extensionsToTry = [extension];
      for (var ext in ['webp', 'png', 'jpg']) {
        if (!extensionsToTry.contains(ext)) extensionsToTry.add(ext);
      }

      for (var ext in extensionsToTry) {
        for (final name in {'$padPage.$ext', '$pageNumber.$ext'}) {
          try {
            final response = await http
                .get(Uri.parse('$baseUrlFormatted$name'))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode != 200 ||
                !await _valid(response.bodyBytes)) {
              continue;
            }
            final target = File('$localDir/$padPage.$ext');
            final temp = await Directory(localDir).createTemp('.image-');
            try {
              final file = await File('${temp.path}/page')
                  .writeAsBytes(response.bodyBytes);
              return await file.rename(target.path);
            } finally {
              await temp.delete(recursive: true);
            }
          } on Exception catch (e) {
            debugPrint('Unable to load $name: $e');
          }
        }
      }

      debugPrint('Failed to download image with any extension');
      return null;
    } catch (e) {
      debugPrint('Error getting page image: $e');
      return null;
    }
  }

  static Future<bool> isPageCached(
    String mushafId,
    int pageNumber, {
    String extension = 'jpg',
  }) async {
    final localDir = await getLocalPath(mushafId);
    final padPage = pageNumber.toString().padLeft(3, '0');
    final file = File('$localDir/$padPage.$extension');
    return await file.exists() && await _valid(await file.readAsBytes());
  }
}
