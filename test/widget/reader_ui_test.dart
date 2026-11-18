import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/presentation/widgets/reader_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/screens/mushaf/mushaf_screen.dart';
import 'package:mathani/presentation/screens/surah_list/surah_list_screen.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';

class _Metadata extends ChangeNotifier implements MushafMetadataProvider {
  String id = 'test-digital';
  String type = 'digital';
  int typeReads = 0;
  @override
  String get currentMushafId => id;
  @override
  String get currentMushafType {
    typeReads++;
    return type;
  }

  void switchToFont() {
    id = 'test-font';
    type = 'font_v2';
    notifyListeners();
  }

  @override
  List<MushafMetadata> get availableMushafs => [
    MushafMetadata()
      ..identifier = currentMushafId
      ..pageCount = 5,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quran extends ChangeNotifier implements QuranProvider {
  @override
  List<Surah> get surahs => [
    Surah()
      ..number = 1
      ..nameArabic = 'الفاتحة'
      ..numberOfAyahs = 7,
    Surah()
      ..number = 2
      ..nameArabic = 'البقرة'
      ..numberOfAyahs = 286,
    Surah()
      ..number = 3
      ..nameArabic = 'آل عمران'
      ..numberOfAyahs = 200,
  ];
  @override
  List<Ayah> get searchResults => [];
  @override
  bool get isLoading => false;
  @override
  bool get isSearching => false;
  @override
  String? get errorMessage => null;
  @override
  int get readingSurah => 1;
  @override
  int get readingAyah => 1;
  @override
  Future<void> loadSurahs() async {}
  @override
  Future<List<Ayah>> getAyahsForPage(int page) async => [];
  @override
  void updateReadingLocation(int surah, int ayah) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;
  @override
  void setContext(int surah, int ayah) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Only supplies the existing reader listener; no model or inference is started.
class _InactiveRecitation extends ChangeNotifier implements RecitationProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bookmarks extends ChangeNotifier implements BookmarkProvider {
  @override
  bool isBookmarked(int surah, int ayah) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const wakelockChannel =
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
  const readerSystemChannel = MethodChannel('mathani/reader_system_ui');
  final systemModes = <bool>[];
  late UiProvider ui;
  late SettingsProvider settings;
  late _Quran quran;
  late _Metadata metadata;
  late _Audio audio;
  late _InactiveRecitation inactive;
  late _Bookmarks bookmarks;
  late MushafNavigationProvider navigation;

  setUp(() {
    systemModes.clear();
    SharedPreferences.setMockInitialValues({});
    ui = UiProvider();
    settings = SettingsProvider();
    quran = _Quran();
    metadata = _Metadata();
    audio = _Audio();
    inactive = _InactiveRecitation();
    bookmarks = _Bookmarks();
    navigation = MushafNavigationProvider();
    binding.defaultBinaryMessenger.setMockMessageHandler(
      wakelockChannel,
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      readerSystemChannel,
      (call) async {
        systemModes.add(call.arguments as bool);
        return null;
      },
    );
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      readerSystemChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMessageHandler(wakelockChannel, null);
    for (final notifier in <ChangeNotifier>[
      ui,
      settings,
      quran,
      metadata,
      audio,
      inactive,
      bookmarks,
      navigation,
    ]) {
      notifier.dispose();
    }
  });

  Future<void> show(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UiProvider>.value(value: ui),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<QuranProvider>.value(value: quran),
          ChangeNotifierProvider<MushafMetadataProvider>.value(value: metadata),
          ChangeNotifierProvider<AudioProvider>.value(value: audio),
          ChangeNotifierProvider<RecitationProvider>.value(value: inactive),
          ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarks),
          ChangeNotifierProvider<MushafNavigationProvider>.value(
            value: navigation,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: appLocalizationDelegates,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
    'page taps toggle immersive mode without an extra floating button',
    (tester) async {
      await show(tester, const MushafScreen(initialPage: 3));
      expect(ui.isImmersiveMode, isFalse);
      expect(
        find.byKey(const ValueKey('reader-controls-toggle')),
        findsNothing,
      );
      final page = find.byType(PageView);
      await tester.tapAt(tester.getTopLeft(page) + const Offset(20, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(ui.isImmersiveMode, isTrue);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const ValueKey('reader-page-header')), findsOneWidget);
      await tester.tapAt(tester.getTopLeft(page) + const Offset(20, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(ui.isImmersiveMode, isFalse);
      expect(systemModes, [false, true, false]);
      expect(ui.currentMushafPage, 3);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'one cold load and delayed indicator without a separate app bar',
    (tester) async {
      GlyphDataLoader().clearCache();
      final directory = Directory.systemTemp.createTempSync(
        'reader-cold-load-',
      );
      final fonts = Directory('${directory.path}/fonts/qcf4')
        ..createSync(recursive: true);
      File('${fonts.path}/quran_glyphs.json').writeAsStringSync(
        jsonEncode(List.generate(5, (i) => {'page': i + 1, 'lines': []})),
      );
      final gate = Completer<String>();
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) => gate.future,
      );
      addTearDown(() async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
        GlyphDataLoader().clearCache();
        await directory.delete(recursive: true);
      });
      metadata.type = 'font_v2';
      await show(tester, const MushafScreen(initialPage: 3));
      expect(metadata.typeReads, 1);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('جاري تحميل المصحف...'), findsOneWidget);
      gate.complete(directory.path);
      for (var i = 0; i < 40 && find.byType(PageView).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await tester.pump();
      }
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(ReaderLoadingIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'existing page and its state remain while replacement data loads',
    (tester) async {
      await show(tester, const MushafScreen(initialPage: 3));
      final original = find.byWidgetPredicate(
        (w) => w is MushafPageWidget && !w.hideContent && w.page.page == 3,
      );
      final originalState = tester.state(original);
      GlyphDataLoader().clearCache();
      final gate = Completer<String>();
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) => gate.future,
      );
      metadata.switchToFont();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(ReaderLoadingIndicator), findsNothing);
      expect(tester.state(original), same(originalState));
      expect(
        tester.widget<MushafPageWidget>(original).mushafId,
        'test-digital',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      binding.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
      gate.complete('unused-after-dispose');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      GlyphDataLoader().clearCache();
      expect(tester.takeException(), isNull);
    },
  );

  test('opening another view or audio restores controls', () {
    ui.setImmersiveMode(true);
    ui.toggleTafsir();
    expect(ui.isImmersiveMode, isFalse);
    ui.toggleTafsir();
    ui.setImmersiveMode(true);
    ui.setShowFullAudioPlayer(true);
    expect(ui.isImmersiveMode, isFalse);
    ui.setShowFullAudioPlayer(false);
    ui.setImmersiveMode(true);
    ui.jumpToPage(3);
    expect(ui.isImmersiveMode, isFalse);
    ui.setTabIndex(0);
    ui.setImmersiveMode(true);
    expect(ui.isImmersiveMode, isFalse);
  });

  testWidgets('surah index is a single column with full width rows', (
    tester,
  ) async {
    await show(tester, const SurahListScreen());
    final first = find.byKey(const ValueKey('surah-index-1'));
    final second = find.byKey(const ValueKey('surah-index-2'));
    final firstRect = tester.getRect(first);
    final secondRect = tester.getRect(second);
    expect(secondRect.top, greaterThanOrEqualTo(firstRect.bottom));
    expect(secondRect.left, firstRect.left);
    expect(firstRect.width, greaterThan(700));
    expect(find.byType(SliverGrid), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final mode in [0, 1]) {
    testWidgets('reader allows all four directions in mode $mode', (
      tester,
    ) async {
      await settings.setNavigationMode(mode);
      await show(tester, const MushafScreen(initialPage: 2));
      final pages = find.byType(PageView);
      expect(ui.currentMushafPage, 2);
      final next = mode == 0 ? const Offset(0, -240) : const Offset(240, 0);
      final previous = -next;
      await tester.fling(pages, next, 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 3);
      await tester.fling(pages, previous, 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 2);
      final primary = mode == 0 ? const Offset(400, 0) : const Offset(0, -400);
      await tester.fling(pages, primary, 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(ui.currentMushafPage, 3);
      await tester.fling(pages, -primary, 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(ui.currentMushafPage, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final up in [true, false]) {
    testWidgets(
      'vertical settling preserves the incoming page and stops once; up=$up',
      (tester) async {
        await show(tester, const MushafScreen(initialPage: 3));
        final pages = find.byType(PageView);
        final target = up ? 4 : 2;
        final incoming = find.byWidgetPredicate(
          (w) =>
              w is MushafPageWidget && !w.hideContent && w.page.page == target,
        );
        final drag = await tester.startGesture(tester.getCenter(pages));
        await drag.moveBy(Offset(0, up ? -30 : 30));
        await drag.moveBy(Offset(0, up ? -170 : 170));
        await tester.pump();
        expect(incoming, findsOneWidget);
        final incomingState = tester.state(incoming);
        var previousTop = tester.getTopLeft(incoming).dy;
        await drag.up();
        for (var frame = 0; frame < 18; frame++) {
          await tester.pump(const Duration(milliseconds: 32));
          final top = tester.getTopLeft(incoming).dy;
          expect(
            up ? top <= previousTop + .01 : top >= previousTop - .01,
            isTrue,
          );
          previousTop = top;
        }
        expect(ui.currentMushafPage, target);
        expect(tester.state(incoming), same(incomingState));
        final settled = tester.getRect(incoming);
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.getRect(incoming), settled);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('diagonal swipes choose one direction and advance one page', (
    tester,
  ) async {
    await show(tester, const MushafScreen(initialPage: 2));
    final pages = find.byType(PageView);
    for (final movement in [
      const Offset(320, -50),
      const Offset(-320, 50),
      const Offset(50, -240),
      const Offset(-50, 240),
    ]) {
      final before = ui.currentMushafPage;
      final forward = movement.dx.abs() > movement.dy.abs()
          ? movement.dx > 0
          : movement.dy < 0;
      await tester.fling(pages, movement, 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(ui.currentMushafPage, before + (forward ? 1 : -1));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final mode in [2, 3]) {
    testWidgets('header remains above the scrolling viewport in mode $mode', (
      tester,
    ) async {
      await settings.setNavigationMode(mode);
      await show(tester, const MushafScreen(initialPage: 3));
      final header = find.byKey(const ValueKey('reader-page-header'));
      final viewport = find.byKey(const ValueKey('reader-page-viewport'));
      expect(tester.getBottomLeft(header).dy, tester.getTopLeft(viewport).dy);
      ui.setImmersiveMode(true);
      await tester.pump();
      expect(header, findsOneWidget);
      expect(ui.currentMushafPage, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'page edges do not wrap and cancelled drags keep the current page',
    (tester) async {
      await show(tester, const MushafScreen(initialPage: 5));
      final pages = find.byType(PageView);
      await tester.fling(pages, const Offset(0, -240), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 5);
      ui.jumpToPage(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 1);
      await tester.fling(pages, const Offset(0, 240), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 1);
      final gesture = await tester.startGesture(tester.getCenter(pages));
      await gesture.moveBy(const Offset(0, -180));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is MushafPageWidget && !w.hideContent && w.page.page == 1,
        ),
        findsOneWidget,
      );
      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 100));
      expect(ui.currentMushafPage, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'changing direction during an animation cancels the old transition safely',
    (tester) async {
      await show(tester, const MushafScreen(initialPage: 2));
      final pages = find.byType(PageView);
      await tester.fling(pages, const Offset(0, -240), 1200);
      await tester.pump();
      await settings.setNavigationMode(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 2);
      await tester.fling(pages, const Offset(240, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ui.currentMushafPage, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'page header stays integrated and visible in both reading modes',
    (tester) async {
      await show(tester, const MushafScreen(initialPage: 3));
      final viewport = tester.getRect(find.byType(PageView));
      final header = find.byWidgetPredicate(
        (w) => w is MushafPageWidget && w.hideContent,
      );
      expect(header, findsOneWidget);
      expect(tester.getSize(header).height, 45);
      expect(tester.getBottomLeft(header).dy, viewport.top);
      final headerWidget = tester.widget<MushafPageWidget>(header);
      expect(headerWidget.paintBackground, isFalse);
      final bodies = tester.widgetList<MushafPageWidget>(
        find.byWidgetPredicate((w) => w is MushafPageWidget && !w.hideContent),
      );
      expect(bodies.every((w) => !w.paintBackground), isTrue);
      ui.setImmersiveMode(true);
      await tester.pump();
      expect(header, findsOneWidget);
      expect(tester.getRect(find.byType(PageView)), viewport);
      ui.setImmersiveMode(false);
      await tester.pump();
      expect(header, findsOneWidget);
      expect(ui.currentMushafPage, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
