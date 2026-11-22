import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';
import 'package:mathani/l10n/app_localization_delegates.dart';
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/presentation/screens/bookmarks/bookmarks_screen.dart';

class _Quran extends ChangeNotifier implements QuranProvider {
  @override
  List<Surah> get surahs => [
    Surah()
      ..number = 2
      ..nameArabic = 'البقرة'
      ..nameEnglish = 'Al-Baqarah'
      ..page = 2,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bookmarks extends ChangeNotifier implements BookmarkProvider {
  @override
  List<Bookmark> get bookmarks => [
    Bookmark()
      ..id = 123
      ..surahNumber = 2
      ..ayahNumber = 282,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('all Madani page boundaries match the bundled Quran', () async {
    final source = jsonDecode(
      await File('assets/data/quran_advanced.json').readAsString(),
    ) as List;
    final pages = <int, List<(int, int)>>{};
    for (final s in source) {
      for (final verse in s['verses']) {
        pages.putIfAbsent(verse['page'], () => []).add((s['id'], verse['id']));
      }
    }
    final nav = MushafNavigationProvider();
    addTearDown(nav.dispose);
    await nav.updateMushaf('qcf2_v4_woff2');
    expect(pages.length, 604);
    for (final entry in pages.entries) {
      final page = nav.getPageInfo(entry.key)!;
      expect(
        (page.startSurah, page.startAyah),
        entry.value.first,
        reason: 'page ${entry.key}',
      );
      expect(
        (page.endSurah, page.endAyah),
        entry.value.last,
        reason: 'page ${entry.key}',
      );
      expect(page.surahs, entry.value.map((v) => v.$1).toSet().toList());
    }
  });
  testWidgets('tapping the bookmark for 2:282 opens page 48', (tester) async {
    final ui = UiProvider();
    final nav = MushafNavigationProvider();
    await nav.updateMushaf('qcf2_v4_woff2');
    final quran = _Quran();
    final bookmarks = _Bookmarks();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UiProvider>.value(value: ui),
          ChangeNotifierProvider<MushafNavigationProvider>.value(value: nav),
          ChangeNotifierProvider<QuranProvider>.value(value: quran),
          ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarks),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
          home: const Scaffold(body: BookmarksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dismissible),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pump();
    expect(MushafNavigationProvider.pageForSurahAyah(2, 282), 48);
    expect(ui.pageToJump, 48);
    await tester.pumpWidget(const SizedBox.shrink());
    ui.dispose();
    nav.dispose();
    quran.dispose();
    bookmarks.dispose();
  });
}
