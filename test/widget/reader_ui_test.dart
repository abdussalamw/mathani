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
import 'package:mathani/presentation/widgets/reader_controls_toggle.dart';

class _Metadata extends ChangeNotifier implements MushafMetadataProvider {
  @override
  String get currentMushafId => 'test-digital';
  @override
  String get currentMushafType => 'digital';
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
  late UiProvider ui;
  late SettingsProvider settings;
  late _Quran quran;
  late _Metadata metadata;
  late _Audio audio;
  late _InactiveRecitation inactive;
  late _Bookmarks bookmarks;
  late MushafNavigationProvider navigation;

  setUp(() {
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
  });
  tearDown(() {
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

  testWidgets('controls start visible and remain recoverable after hiding', (
    tester,
  ) async {
    await show(tester, const ReaderControlsToggle());
    expect(ui.isImmersiveMode, isFalse);
    await tester.tap(find.byKey(const ValueKey('reader-controls-toggle')));
    await tester.pump();
    expect(ui.isImmersiveMode, isTrue);
    expect(find.byTooltip('إظهار الشريطين العلوي والسفلي'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader-controls-toggle')));
    expect(ui.isImmersiveMode, isFalse);
  });

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

  testWidgets('hiding the fixed header preserves page and viewport size', (
    tester,
  ) async {
    await show(tester, const MushafScreen(initialPage: 3));
    final viewport = tester.getRect(find.byType(PageView));
    final header = find.byWidgetPredicate(
      (w) => w is MushafPageWidget && w.hideContent,
    );
    expect(header, findsOneWidget);
    ui.setImmersiveMode(true);
    await tester.pump();
    expect(header, findsNothing);
    expect(tester.getRect(find.byType(PageView)), viewport);
    ui.setImmersiveMode(false);
    await tester.pump();
    expect(header, findsOneWidget);
    expect(ui.currentMushafPage, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
