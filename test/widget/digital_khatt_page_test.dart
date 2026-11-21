import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/services/digital_khatt_page_loader.dart';
import 'package:mathani/presentation/widgets/digital_khatt_mushaf_page_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('DigitalKhattMadina')
      ..addFont(rootBundle.load('assets/fonts/digital_khatt/madina.otf'));
    await loader.load();
    final oldMadinaFontLoader = FontLoader('DigitalKhattOldMadina')
      ..addFont(rootBundle.load('assets/fonts/digital_khatt/oldmadina.otf'));
    await oldMadinaFontLoader.load();
    await digitalKhattPageLoader.loadPage(1);
    await digitalKhattOldMadinaLoader.loadPage(1);
  });

  testWidgets(
    'the single font shapes offline lines and selects the pressed verse',
    (tester) async {
      (int, int)? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 620,
              child: DigitalKhattMushafPageWidget(
                pageNumber: 1,
                onAyahLongPress: (s, a) => selected = (s, a),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lines = find.descendant(
        of: find.byType(DigitalKhattMushafPageWidget),
        matching: find.byType(RichText),
      );
      expect(lines, findsNWidgets(8));
      final paragraph = tester
          .renderObjectList<RenderParagraph>(lines)
          .firstWhere((p) => p.text.toPlainText().contains('۝٤'));
      final text = paragraph.text.toPlainText();
      final mark = text.indexOf('مَٰلِكِ');
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: mark, extentOffset: mark + 4),
      );
      final point = paragraph.localToGlobal(boxes.first.toRect().center);
      await tester.tapAt(point);
      expect(selected, isNull);
      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 360));
      await gesture.up();
      expect(selected, (1, 4));
      await tester.pumpWidget(
        const MaterialApp(home: DigitalKhattMushafPageWidget(pageNumber: 604)),
      );
      await tester.pumpAndSettle();
      expect(lines, findsNWidgets(15));
      for (final rich in tester.widgetList<RichText>(lines)) {
        expect(rich.text.style!.fontFamily, 'DigitalKhattMadina');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps the last word visible on every reference line', (
    tester,
  ) async {
    for (final page in [1, 2, 3, 48, 50, 604]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 620,
              child: DigitalKhattMushafPageWidget(pageNumber: page),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lines = find.descendant(
        of: find.byType(DigitalKhattMushafPageWidget),
        matching: find.byType(RichText),
      );
      expect(lines, findsNWidgets(page <= 2 ? 8 : 15));
      for (final p in tester.renderObjectList<RenderParagraph>(lines)) {
        final text = p.text.toPlainText();
        final last = p.getBoxesForSelection(
          TextSelection(
            baseOffset: text.lastIndexOf(' ') + 1,
            extentOffset: text.length,
          ),
        );
        expect(last, isNotEmpty, reason: 'page $page: $text');
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        final row = boxes.first;
        for (final box in boxes) {
          expect(
            box.top,
            closeTo(row.top, 0.1),
            reason: 'wrapped on page $page',
          );
          expect(
            box.left,
            greaterThanOrEqualTo(-1.0),
            reason: 'clipped on page $page',
          );
          expect(
            box.right,
            lessThanOrEqualTo(p.size.width + 1),
            reason: 'clipped on page $page',
          );
        }
      }
    }
  });

  testWidgets(
    'colors the indexed word when a verse continues on the next line',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DigitalKhattMushafPageWidget(
            pageNumber: 1,
            wordVerdicts: {'1_7_4': WordVerdict.incorrect},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paintedWords = <String>[];
      final lines = find.descendant(
        of: find.byType(DigitalKhattMushafPageWidget),
        matching: find.byType(RichText),
      );
      for (final line in tester.widgetList<RichText>(lines)) {
        line.text.visitChildren((span) {
          if (span is TextSpan && span.style?.backgroundColor != null) {
            paintedWords.add(span.text!.trim());
          }
          return true;
        });
      }
      expect(paintedWords, ['عَلَيْهِمْ']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Old Madina 1995 single font shapes lines and selects the pressed verse',
    (tester) async {
      (int, int)? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 620,
              child: DigitalKhattMushafPageWidget(
                pageNumber: 1,
                fontFamily: 'DigitalKhattOldMadina',
                loader: digitalKhattOldMadinaLoader,
                onAyahLongPress: (s, a) => selected = (s, a),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lines = find.descendant(
        of: find.byType(DigitalKhattMushafPageWidget),
        matching: find.byType(RichText),
      );
      expect(lines, findsNWidgets(8));
      for (final rich in tester.widgetList<RichText>(lines)) {
        expect(rich.text.style!.fontFamily, 'DigitalKhattOldMadina');
      }

      final paragraph = tester
          .renderObjectList<RenderParagraph>(lines)
          .firstWhere((p) => p.text.toPlainText().contains('۝٤'));
      final text = paragraph.text.toPlainText();
      final mark = text.indexOf('مَٰلِكِ');
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: mark, extentOffset: mark + 4),
      );
      final point = paragraph.localToGlobal(boxes.first.toRect().center);
      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 360));
      await gesture.up();
      expect(selected, (1, 4));

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 620,
              child: DigitalKhattMushafPageWidget(
                pageNumber: 604,
                fontFamily: 'DigitalKhattOldMadina',
                loader: digitalKhattOldMadinaLoader,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lines604 = find.descendant(
        of: find.byType(DigitalKhattMushafPageWidget),
        matching: find.byType(RichText),
      );
      expect(lines604, findsNWidgets(15));
      for (final rich in tester.widgetList<RichText>(lines604)) {
        expect(rich.text.style!.fontFamily, 'DigitalKhattOldMadina');
      }
      expect(tester.takeException(), isNull);
    },
  );
}
