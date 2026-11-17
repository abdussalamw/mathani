import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoButton, CupertinoLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/core/theme/app_theme.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/l10n/app_localizations.dart';

void main() {
  for (final dark in [false, true]) {
    for (final language in ['ar', 'en']) {
      testWidgets('Material and Cupertino work in $language with dark=$dark', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Builder(
              builder: (context) {
                expect(
                  Directionality.of(context),
                  language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                );
                expect(
                  Theme.of(context).brightness,
                  dark ? Brightness.dark : Brightness.light,
                );
                expect(
                  MaterialLocalizations.of(context).okButtonLabel,
                  isNotEmpty,
                );
                expect(
                  CupertinoLocalizations.of(context).alertDialogLabel,
                  isNotEmpty,
                );
                expect(AppLocalizations.of(context)?.localeName, language);
                return Scaffold(
                  appBar: AppBar(title: const Text('مثاني')),
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('اختبار'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  MaterialLocalizations.of(context)
                                      .okButtonLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('فتح'),
                      ),
                      CupertinoButton(
                        onPressed: () {},
                        child: const Text('زر'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
