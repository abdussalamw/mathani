import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/l10n/app_localizations.dart';
import 'package:mathani/presentation/widgets/reader_loading_indicator.dart';

void main() {
  for (final locale in ['ar', 'en']) {
    testWidgets('loading is delayed and uses localized text in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationDelegates,
          home: const Scaffold(body: ReaderLoadingIndicator()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final context = tester.element(find.byType(ReaderLoadingIndicator));
      expect(
        find.text(AppLocalizations.of(context)!.loadingMushaf),
        findsOneWidget,
      );
      expect(find.byType(AppBar), findsNothing);
    });
  }

  testWidgets('fast completion cancels loading indicator without a flash', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReaderLoadingIndicator()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
