import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/data/models/reciter.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/domain/entities/review_summary.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/widgets/audio_player_sheet.dart';
import 'package:mathani/presentation/widgets/review_summary_card.dart';
import 'package:provider/provider.dart';

class _Player implements AudioPlayer {
  @override
  double get speed => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  AudioPlayer get player => _Player();
  @override
  int get currentSurah => 1;
  @override
  int get currentAyah => 1;
  @override
  int get startSurah => 1;
  @override
  int get startAyah => 1;
  @override
  int get endSurah => 1;
  @override
  int get endAyah => 1;
  @override
  int ayahRepeatLimit = 1;
  @override
  int get rangeRepeatLimit => 1;
  @override
  bool get isLoading => false;
  @override
  bool get isPlaying => false;
  @override
  String? get lastError => null;
  @override
  Reciter get currentReciter =>
      Reciter(id: 'test', name: 'قارئ الاختبار', style: '', bitrate: '');
  @override
  List<({int index, MediaItem item})> get upcomingTracks => [];
  @override
  void setAyahRepeatLimit(int value) {
    ayahRepeatLimit = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quran extends ChangeNotifier implements QuranProvider {
  @override
  int get readingSurah => 1;
  @override
  int get readingAyah => 1;
  @override
  List<Surah> get surahs => [
    Surah()
      ..number = 1
      ..nameArabic = 'الفاتحة'
      ..numberOfAyahs = 7,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget app(Widget child) => MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: appLocalizationDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: Scaffold(body: child),
  );

  testWidgets('audio controls remain usable at 320px with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = _Audio();
    final quran = _Quran();
    final ui = UiProvider();
    addTearDown(audio.dispose);
    addTearDown(quran.dispose);
    addTearDown(ui.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: audio),
          ChangeNotifierProvider<QuranProvider>.value(value: quran),
          ChangeNotifierProvider<UiProvider>.value(value: ui),
        ],
        child: app(
          const Align(
            alignment: Alignment.bottomCenter,
            child: AudioPlayerSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('الآية التالية'), findsOneWidget);
    final increment = find.byTooltip('زيادة تكرار الآية');
    await tester.ensureVisible(increment);
    await tester.pumpAndSettle();
    await tester.tap(increment);
    await tester.pump();
    expect(audio.ayahRepeatLimit, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly review action wraps and works with enlarged Arabic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = RecitationSession()
      ..surahName = 'الفاتحة'
      ..accuracyPercent = 70;
    var tapped = false;
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: ReviewSummaryCard(
            summary: ReviewSummary.fromSessions([session]),
            onReview: () async {
              tapped = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.tap(find.byType(OutlinedButton));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
