import 'package:mathani/presentation/widgets/reader_page_frame.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/data/services/qcf4_alignment_service.dart';
import 'package:mathani/data/services/qcf4_font_downloader.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/widgets/mushaf_image_widget.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/presentation/widgets/page_line_widget.dart';

class _Quran extends ChangeNotifier implements QuranProvider {
  @override
  Future<List<Ayah>> getAyahsForPage(int page) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bookmarks extends ChangeNotifier implements BookmarkProvider {
  @override
  bool isBookmarked(int surah, int ayah) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InactiveRecitation extends ChangeNotifier implements RecitationProvider {
  @override
  Map<String, WordVerdict> get liveWordVerdicts => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const pathsChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory cache;
  late SettingsProvider settings;
  late _Quran quran;
  late _Bookmarks bookmarks;
  late _InactiveRecitation recitation;
  late UiProvider ui;
  late MushafNavigationProvider navigation;
  final page = PageGlyph(
    page: 3,
    lines: List.generate(
      15,
      (index) => PageLine(
        line: index + 1,
        glyphs: List.generate(
          8,
          (word) => Glyph(
            code: 'بِسْمِ',
            type: 1,
            surah: 2,
            ayah: index + 1,
            wordId: word + 1,
          ),
        ),
      ),
    ),
  );

  setUpAll(() async {
    cache = Directory.systemTemp.createTempSync('reader_page_bounds_');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathsChannel,
      (_) async => cache.path,
    );
    final fonts = Directory('${cache.path}/fonts/qcf4')
      ..createSync(recursive: true);
    // A bundled Arabic font exercises real FontLoader and glyph layout without
    // downloading page fonts. These fixtures test bounds, not QCF4 glyph mapping.
    final bytes = File('assets/fonts/KFGQPC_HAFS.ttf').readAsBytesSync();
    for (final number in [2, 3, 4]) {
      File('${fonts.path}/QCF4_${number.toString().padLeft(3, '0')}.woff')
          .writeAsBytesSync(bytes);
      expect(await QCF4FontDownloader.loadPageFont(number), isTrue);
    }
    File('${fonts.path}/qcf4_line_alignment.json').writeAsStringSync('{}');
    await QCF4AlignmentService().load();
    final images = Directory('${cache.path}/mushafs/bounds-image')
      ..createSync(recursive: true);
    File('assets/images/mushaf_texture.png').copySync('${images.path}/003.png');
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathsChannel, null);
    cache.deleteSync(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    await settings.setBackgroundColorMode('old');
    quran = _Quran();
    bookmarks = _Bookmarks();
    recitation = _InactiveRecitation();
    ui = UiProvider();
    navigation = MushafNavigationProvider();
  });

  tearDown(() {
    for (final notifier in <ChangeNotifier>[
      settings,
      quran,
      bookmarks,
      recitation,
      ui,
      navigation,
    ]) {
      notifier.dispose();
    }
  });

  Future<void> show(
    WidgetTester tester, {
    required bool immersive,
    bool image = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: immersive ? 0 : 24, bottom: 24);
    tester.view.viewPadding = FakeViewPadding(
      top: immersive ? 0 : 24,
      bottom: 24,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<QuranProvider>.value(value: quran),
          ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarks),
          ChangeNotifierProvider<RecitationProvider>.value(value: recitation),
          ChangeNotifierProvider<UiProvider>.value(value: ui),
          ChangeNotifierProvider<MushafNavigationProvider>.value(
            value: navigation,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: immersive
                ? null
                : const SafeArea(
                    top: false,
                    child: SizedBox(key: ValueKey('app-navbar'), height: 76),
                  ),
            body: ReaderPageFrame(
              immersive: immersive,
              child: Column(
                children: [
                  SizedBox(
                    height: 45,
                    child: MushafPageWidget(
                      key: const ValueKey('page-header'),
                      page: page,
                      hideContent: true,
                      paintBackground: false,
                      headerHeight: 45,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      key: const ValueKey('body-region'),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: image
                          ? const MushafImageWidget(
                              pageNumber: 3,
                              mushafId: 'bounds-image',
                              baseUrl: 'https://unused.invalid',
                              showInfo: false,
                            )
                          : MushafPageWidget(
                              page: page,
                              showInfo: false,
                              paintBackground: false,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // File-backed image loading needs real asynchronous filesystem completion.
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
    'all 15 line positions stay fixed when bars are hidden and restored',
    (tester) async {
      await show(tester, immersive: false);
      final initial = tester
          .widgetList<PageLineWidget>(find.byType(PageLineWidget))
          .map((line) => tester.getRect(find.byWidget(line)))
          .toList();
      final header = tester.getRect(find.byKey(const ValueKey('page-header')));
      expect(initial.length, 15);
      await show(tester, immersive: true);
      expect(tester.getRect(find.byKey(const ValueKey('page-header'))), header);
      final hidden = tester
          .widgetList<PageLineWidget>(find.byType(PageLineWidget))
          .map((line) => tester.getRect(find.byWidget(line)))
          .toList();
      expect(hidden, initial);
      await show(tester, immersive: false);
      final restored = tester
          .widgetList<PageLineWidget>(find.byType(PageLineWidget))
          .map((line) => tester.getRect(find.byWidget(line)))
          .toList();
      expect(restored, initial);
      expect(tester.takeException(), isNull);
    },
  );

  for (final immersive in [false, true]) {
    testWidgets('15 loaded lines fit the reader region; immersive=$immersive', (
      tester,
    ) async {
      await show(tester, immersive: immersive);
      expect(QCF4FontDownloader.isFontLoaded(3), isTrue);
      expect(find.byType(PageLineWidget), findsNWidgets(15));
      final header = find.byKey(const ValueKey('page-header'));
      final headerRect = tester.getRect(header);
      final region = tester.getRect(find.byKey(const ValueKey('body-region')));
      final lines = find.byType(PageLineWidget);
      Rect glyphBounds(Finder line) => find
          .descendant(of: line, matching: find.byType(Text))
          .evaluate()
          .map((element) => tester.getRect(find.byWidget(element.widget)))
          .reduce((left, right) => left.expandToInclude(right));
      final first = glyphBounds(lines.first);
      final last = glyphBounds(lines.last);
      expect(headerRect.height, 45);
      expect(headerRect.top, immersive ? 0 : 24);
      expect(region.top, headerRect.bottom);
      expect(first.top, greaterThanOrEqualTo(region.top + 12 - 0.001));
      expect(last.bottom, lessThanOrEqualTo(region.bottom - 12 + 0.001));
      expect(first.top - region.top, closeTo(region.bottom - last.bottom, 0.1));
      expect(region.bottom, immersive ? 820 : 744);
      final headerSurface = tester.widget<AnimatedContainer>(
        find
            .descendant(of: header, matching: find.byType(AnimatedContainer))
            .first,
      );
      expect(headerSurface.decoration, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'image body uses supplied reader bounds without extra bottom gap',
    (tester) async {
      await show(tester, immersive: true, image: true);
      final region = tester.getRect(find.byKey(const ValueKey('body-region')));
      final imageViewport = tester.getRect(find.byType(InteractiveViewer));
      expect(imageViewport.top, region.top + 12);
      expect(imageViewport.bottom, region.bottom - 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
