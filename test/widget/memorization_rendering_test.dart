import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/data/services/digital_khatt_page_loader.dart';
import 'package:mathani/presentation/widgets/digital_khatt_mushaf_page_widget.dart';
import 'package:mathani/presentation/widgets/page_line_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('DigitalKhattMadina')
      ..addFont(rootBundle.load('assets/fonts/digital_khatt/madina.otf'));
    await font.load();
    await digitalKhattPageLoader.loadPage(1);
    await digitalKhattOldMadinaLoader.loadPage(339);
  });

  testWidgets('single-font reveal retains line layout and section markers', (
    tester,
  ) async {
    Future<void> show(Set<String>? revealed) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 370,
              height: 600,
              child: DigitalKhattMushafPageWidget(
                pageNumber: 1,
                revealedWordKeys: revealed,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    final lines = find.descendant(
      of: find.byType(DigitalKhattMushafPageWidget),
      matching: find.byType(RichText),
    );
    List<Rect> bounds() => [
      for (final paragraph in tester.renderObjectList<RenderParagraph>(lines))
        paragraph.localToGlobal(Offset.zero) & paragraph.size,
    ];
    String announcedText() => tester
        .widgetList<RichText>(lines)
        .map((line) => line.text.toPlainText())
        .join(' ');

    await show(null);
    final original = bounds();
    expect(announcedText(), contains('عَلَيْهِمْ'));

    await show(const {});
    expect(bounds(), original);
    expect(announcedText(), isNot(contains('عَلَيْهِمْ')));
    expect(announcedText(), contains('۝٧'));

    // This word is on the second line of the same ayah.
    await show(const {'1_7_4'});
    expect(bounds(), original);
    expect(announcedText(), contains('عَلَيْهِمْ'));
    expect(announcedText(), isNot(contains('صِرَٰطَ')));

    await show(null);
    expect(bounds(), original);
    expect(announcedText(), contains('صِرَٰطَ'));
  });

  testWidgets('the old Madina quarter marker keeps the first word index', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DigitalKhattMushafPageWidget(
          pageNumber: 339,
          loader: digitalKhattOldMadinaLoader,
          revealedWordKeys: const {'22_60_1'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final lines = find.descendant(
      of: find.byType(DigitalKhattMushafPageWidget),
      matching: find.byType(RichText),
    );
    final text = tester
        .widgetList<RichText>(lines)
        .map((line) => line.text.toPlainText())
        .join(' ');
    expect(text, contains('۞ ذَٰلِكَ'));
    expect(text, isNot(contains('وَمَنْ')));
  });

  testWidgets('hidden glyphs retain their position and are not announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final first = Glyph(code: 'الرَّحْمَٰنِ', type: 1, surah: 1, ayah: 3);
    final second = Glyph(code: 'الرَّحِيمِ', type: 1, surah: 1, ayah: 3);
    final line = PageLine(line: 1, glyphs: [first, second]);

    Future<void> show(Set<String>? revealed) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PageLineWidget(
            line: line,
            pageNumber: 1,
            isParentFontLoaded: true,
            wordKeys: {first: '1_3_1', second: '1_3_2'},
            revealedWordKeys: revealed,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(null);
    final positions = [
      tester.getRect(find.text(first.code)),
      tester.getRect(find.text(second.code)),
    ];

    await show(const {'1_3_1'});
    expect(tester.getRect(find.text(first.code)), positions[0]);
    expect(tester.getRect(find.text(second.code)), positions[1]);
    expect(find.bySemanticsLabel(first.code), findsOneWidget);
    expect(find.bySemanticsLabel(second.code), findsNothing);

    await show(null);
    expect(find.bySemanticsLabel(second.code), findsOneWidget);
    semantics.dispose();
  });
}
