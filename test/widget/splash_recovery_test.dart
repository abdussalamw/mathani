import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart';
import 'package:mathani/presentation/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';

class _Metadata extends ChangeNotifier implements MushafMetadataProvider {
  @override
  Object? initializationError;
  bool ready = false;
  @override
  bool get isInitialized => true;
  @override
  String get currentMushafId => 'qcf2_v4_woff2';
  @override
  List<MushafMetadata> get availableMushafs => [
    MushafMetadata()
      ..identifier = currentMushafId
      ..isDownloaded = ready,
  ];
  @override
  Future<void> refresh() async {
    initializationError = null;
    ready = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> show(WidgetTester tester, _Metadata provider) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MushafMetadataProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const Text('reader'),
            '/initial_download': (_) => const Text('download'),
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('startup storage failure can retry and open the ready reader', (
    tester,
  ) async {
    final metadata = _Metadata()
      ..initializationError = StateError('storage unavailable');
    await show(tester, metadata);
    expect(find.text('reader'), findsNothing);
    expect(find.text('download'), findsNothing);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('reader'), findsOneWidget);
  });
  testWidgets('a missing selected mushaf opens the download route', (
    tester,
  ) async {
    await show(tester, _Metadata());
    expect(find.text('download'), findsOneWidget);
  });
}
