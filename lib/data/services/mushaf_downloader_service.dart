import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MushafDownloaderService {
  /// Extracts into a staging directory supplied by the installer. The caller
  /// validates all parts of the package before committing that directory.
  static Future<void> downloadAndExtract({
    required String url,
    required String destinationPath,
    required Function(double progress) onProgress,
  }) async {
    final dest = await Directory(destinationPath).create(recursive: true);
    final scratch = await dest.createTemp('.download-');
    final client = http.Client();
    const timeout = Duration(seconds: 30);
    try {
      final uri = Uri.parse(url);
      final response = await client
          .send(http.Request('GET', uri))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final downloaded = File('${scratch.path}/download');
      var received = 0;
      final length = response.contentLength;
      final stream = response.stream.timeout(timeout).map((chunk) {
        received += chunk.length;
        if (length != null && length > 0) onProgress(0.7 * received / length);
        return chunk;
      });
      final sink = downloaded.openWrite();
      try {
        await sink.addStream(stream);
      } finally {
        await sink.close();
      }
      if (received == 0 || (length != null && received != length)) {
        throw const FormatException('Incomplete download');
      }
      final name = uri.pathSegments.last;
      if (name.endsWith('.zip') ||
          name.endsWith('.tar.bz2') ||
          name.endsWith('.tar.gz') ||
          name.endsWith('.tgz')) {
        onProgress(0.75);
        await compute(_extract, (downloaded.path, dest.path, name));
      } else {
        await downloaded.rename('${dest.path}/$name');
      }
      onProgress(1.0);
    } finally {
      client.close();
      await scratch.delete(recursive: true);
    }
  }

  static void _extract((String, String, String) args) {
    final (source, dest, name) = args;
    final input = InputFileStream(source);
    var files = 0;
    void extract(ArchiveFile entry) {
      if (!entry.isFile || entry.isSymbolicLink) return;
      final leaf = entry.name.replaceAll('\\', '/').split('/').last;
      if (leaf.isEmpty || leaf.startsWith('.') || leaf.contains(':')) return;
      final output = OutputFileStream('$dest/$leaf');
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
      files++;
    }

    try {
      if (name.endsWith('.zip')) {
        ZipDecoder().decodeStream(input, verify: true, callback: extract);
      } else {
        final tar = name.endsWith('.tar.bz2')
            ? BZip2Decoder().decodeLazy(input, verify: true)
            : GZipDecoder().decodeLazy(input, verify: true);
        try {
          TarDecoder().decodeStream(
            tar,
            verify: true,
            callback: extract,
            keepEntries: false,
          );
        } finally {
          tar.closeSync();
        }
      }
      if (files == 0) throw const FormatException('Empty package');
    } finally {
      input.closeSync();
    }
  }
}
