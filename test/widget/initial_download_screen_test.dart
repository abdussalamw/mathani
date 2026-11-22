import 'package:mathani/l10n/app_localization_delegates.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
import 'package:mathani/presentation/screens/startup/initial_download_screen.dart';
import 'package:provider/provider.dart';

class _DownloadProvider extends ChangeNotifier
    implements MushafMetadataProvider {
  late final pendingSelection = Completer<void>();
  bool delaySelection = false;
  bool selectionStarted = false;
  bool throwOnDownload = true;
  bool alreadyDownloaded = false;
  bool multipleMushafs = false;
  bool includeBundledMushaf = false;
  String? selectedId;
  int downloads = 0;
  bool get hasActiveListeners => hasListeners;

  @override
  List<MushafMetadata> get availableMushafs => [
    MushafMetadata()
      ..identifier = 'qcf2_v4_woff2'
      ..nameArabic = 'مصحف المدينة'
      ..isDownloaded = alreadyDownloaded,
    if (multipleMushafs)
      MushafMetadata()
        ..identifier = 'madani_old_v1'
        ..nameArabic = 'مصحف آخر'
        ..isDownloaded = false,
    if (includeBundledMushaf)
      MushafMetadata()
        ..identifier = 'digital_khatt_1441'
        ..nameArabic = 'مصحف المدينة 1441 (تجريبي)'
        ..type = 'single_font'
        ..isDownloaded = true,
  ];

  @override
  bool get isDownloading => false;

  @override
  Future<void> setMushaf(String identifier) async {
    selectedId = identifier;
    selectionStarted = true;
    if (delaySelection) await pendingSelection.future;
  }

  @override
  Future<void> downloadMushaf(String identifier) async {
    downloads++;
    if (throwOnDownload) throw StateError('download failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const channel =
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
  const codec = StandardMessageCodec();
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late _DownloadProvider provider;
  late SettingsProvider settings;
  late int wakelockCalls;

  setUp(() {
    provider = _DownloadProvider();
    settings = SettingsProvider();
    wakelockCalls = 0;
    binding.defaultBinaryMessenger.setMockMessageHandler(channel, (_) async {
      wakelockCalls++;
      return codec.encodeMessage([null]);
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(channel, null);
    provider.dispose();
    settings.dispose();
  });

  Future<void> showScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MushafMetadataProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InitialDownloadScreen(),
          routes: {'/home': (_) => const Text('ready reader')},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the initial instruction before a download starts', (
    tester,
  ) async {
    await showScreen(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InitialDownloadScreen)),
    )!;
    expect(find.text(l10n.initFirstTimeFiles), findsNWidgets(2));
  });

  testWidgets('radio selection is used for the next download', (tester) async {
    provider.multipleMushafs = true;
    await showScreen(tester);
    final secondRadio = find.byType(Radio<String?>).last;
    await tester.ensureVisible(secondRadio);
    await tester.tap(secondRadio);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(provider.selectedId, 'madani_old_v1');
    expect(provider.downloads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bundled single-font mushaf is not offered as a bulk download', (
    tester,
  ) async {
    provider.includeBundledMushaf = true;
    await showScreen(tester);

    expect(find.text('مصحف المدينة 1441 (تجريبي)'), findsNothing);
  });

  testWidgets(
    'a ready mushaf remains readable when optional tafsir setup fails',
    (tester) async {
      provider.alreadyDownloaded = true;
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) async => throw PlatformException(code: 'storage-unavailable'),
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          paths,
          null,
        ),
      );
      await showScreen(tester);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(provider.downloads, 0);
      expect(find.text('متابعة القراءة'), findsOneWidget);
      await tester.tap(find.text('متابعة القراءة'));
      await tester.pumpAndSettle();
      expect(find.text('ready reader'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('allows retry when enabling wakelock fails', (tester) async {
    binding.defaultBinaryMessenger.setMockMessageHandler(channel, (_) async {
      wakelockCalls++;
      return codec.encodeMessage(['wakelock-unavailable', 'Unavailable', null]);
    });
    await showScreen(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(provider.downloads, 0);
    expect(wakelockCalls, 1);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'removes the progress listener and releases wakelock on failure',
    (tester) async {
      await showScreen(tester);
      final listenersBefore = provider.hasActiveListeners;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(provider.downloads, 1);
      expect(wakelockCalls, 2);
      expect(provider.hasActiveListeners, listenersBefore);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(provider.hasActiveListeners, isFalse);
    },
  );

  testWidgets('stops safely when disposed while selecting a mushaf', (
    tester,
  ) async {
    provider.delaySelection = true;
    await showScreen(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(provider.selectionStarted, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(wakelockCalls, 2);
    provider.pendingSelection.complete();
    await tester.pumpAndSettle();
    await tester.pump();
    expect(provider.downloads, 0);
    expect(wakelockCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'does not continue setup when the provider returns without downloading',
    (tester) async {
      provider.throwOnDownload = false;
      await showScreen(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(InitialDownloadScreen)),
      )!;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(provider.downloads, 1);
      expect(find.textContaining(l10n.errorUnknown), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(wakelockCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
