import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/data/services/mushaf_downloader_service.dart';

void main() {
  for (final extension in ['zip', 'tar.bz2']) {
    test(
      'downloads and extracts nested mushaf pages from $extension',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'mushaf-upgrade-',
        );
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
          await directory.delete(recursive: true);
        });
        final pageBytes = [0, 1, 127, 128, 255];
        final archive = Archive()
          ..addFile(ArchiveFile('pages/001.webp', pageBytes.length, pageBytes))
          ..addFile(ArchiveFile('pages/.metadata', 1, [42]));
        final bytes = extension == 'zip'
            ? ZipEncoder().encode(archive)
            : BZip2Encoder().encode(TarEncoder().encode(archive));
        server.listen((request) async {
          request.response.contentLength = bytes.length;
          request.response.add(bytes);
          await request.response.close();
        });
        final progress = <double>[];

        await MushafDownloaderService.downloadAndExtract(
          url: 'http://127.0.0.1:${server.port}/mushaf.$extension',
          destinationPath: directory.path,
          onProgress: progress.add,
        );

        expect(
          await File('${directory.path}/001.webp').readAsBytes(),
          pageBytes,
        );
        expect(File('${directory.path}/.metadata').existsSync(), isFalse);
        expect(Directory('${directory.path}/pages').existsSync(), isFalse);
        expect(progress.last, 1.0);
        expect(progress, everyElement(inInclusiveRange(0.0, 1.0)));
      },
    );
  }
}
