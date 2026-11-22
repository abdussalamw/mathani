import 'dart:io';
import 'dart:convert';

import 'package:mathani/data/services/image_page_loader.dart';
import 'package:mathani/data/services/local_tafsir_service.dart';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mathani/data/services/qcf4_font_downloader.dart';
import 'package:flutter/services.dart';
import 'package:mathani/data/services/mushaf_package.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a rejected tafsir replacement preserves the previous file and text',
    () async {
      final temp = await Directory.systemTemp.createTemp('mathani_tafsir_');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (_) async => temp.path);
      addTearDown(() async {
        messenger.setMockMethodCallHandler(paths, null);
        await temp.delete(recursive: true);
      });
      final service = LocalTafsirService.instance;
      final csv = 'header\n0,0,0,2,0,0,0,0,282,0,0,شرح';
      Future<void> install(String body) => http.runWithClient(
        service.downloadAndExtractTafsir,
        () => MockClient(
          (_) async => http.Response.bytes(utf8.encode(body), 200),
        ),
      );
      await install(csv);
      final old = File('${temp.path}/tafsir/${LocalTafsirService.fileName}');
      await expectLater(install('broken'), throwsException);
      expect(await old.readAsString(), csv);
      expect(service.totalEntries, 1);
      expect(service.isDownloading, isFalse);
    },
  );

  test('repairs cached HTML with a decodable page image', () async {
    final temp = await Directory.systemTemp.createTemp('mathani_image_');
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(paths, (_) async => temp.path);
    addTearDown(() async {
      messenger.setMockMethodCallHandler(paths, null);
      await temp.delete(recursive: true);
    });
    final directory = await ImagePageLoader.getLocalPath('test');
    final target = await File('$directory/001.png')
        .writeAsString('<html>' * 200);
    expect(
      await ImagePageLoader.isPageCached('test', 1, extension: 'png'),
      isFalse,
    );
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMQVDL+DwACFAFmBODefwAAAABJRU5ErkJggg==',
    );
    final page = await http.runWithClient(
      () => ImagePageLoader.getPageImage(
        'test',
        1,
        'https://example.invalid/',
        extension: 'png',
      ),
      () => MockClient((_) async => http.Response.bytes(png, 200)),
    );
    expect(page?.path, target.path);
    expect(
      await ImagePageLoader.isPageCached('test', 1, extension: 'png'),
      isTrue,
    );
  });

  test(
    'restores the previous installation if the staged rename fails',
    () async {
      final root = await Directory.systemTemp.createTemp('mathani_commit_');
      addTearDown(() => root.delete(recursive: true));
      final target = await Directory('${root.path}/live').create();
      final marker = await File('${target.path}/marker').writeAsString('old');
      final stage = Directory('${root.path}/stage');
      expect(
        () => commitMushafDirectory(stage, target),
        throwsA(isA<FileSystemException>()),
      );
      expect(await marker.readAsString(), 'old');
      await target.rename('${target.path}.previous');
      recoverMushafDirectory(target);
      expect(await marker.readAsString(), 'old');
      await stage.create();
      await File('${stage.path}/marker').writeAsString('new');
      commitMushafDirectory(stage, target);
      expect(await marker.readAsString(), 'new');
    },
  );
  test(
    'incomplete QCF archive cannot replace an existing installation',
    () async {
      final temp = await Directory.systemTemp.createTemp('mathani_review_qcf_');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (_) async => temp.path);
      try {
        final oldFont = File('${temp.path}/fonts/qcf4/QCF4_002.woff');
        await oldFont.parent.create(recursive: true);
        await oldFont.writeAsBytes(List.filled(1001, 42));
        final archive = Archive();
        for (final name in [
          'QCF4_001.woff',
          'QCF4_604.woff',
          'quran_glyphs.json',
        ]) {
          archive.addFile(ArchiveFile(name, 1001, List.filled(1001, 42)));
        }
        final bytes = ZipEncoder().encode(archive);
        await expectLater(
          http.runWithClient(
            () => QCF4FontDownloader.downloadAllFonts(
              onProgress: (_) {},
              onStatusChanged: (_) {},
            ),
            () => MockClient((_) async => http.Response.bytes(bytes, 200)),
          ),
          throwsFormatException,
        );
        expect(await oldFont.readAsBytes(), List.filled(1001, 42));
        expect(await QCF4FontDownloader.areAllFontsAvailable(), isFalse);
      } finally {
        messenger.setMockMethodCallHandler(paths, null);
        await temp.delete(recursive: true);
      }
    },
  );
}
