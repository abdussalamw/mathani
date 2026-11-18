import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/presentation/widgets/ayah_press_target.dart';

void main() {
  testWidgets(
    'quick tap is page interaction, selection requires a short hold',
    (tester) async {
      var selections = 0;
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GestureDetector(
            onTap: () => taps++,
            child: Center(
              child: AyahPressTarget(
                onSelected: () => selections++,
                child: const SizedBox(
                  width: 100,
                  height: 60,
                  child: Text('آية'),
                ),
              ),
            ),
          ),
        ),
      );
      final target = find.byType(AyahPressTarget);
      await tester.tap(target);
      await tester.pump();
      expect(selections, 0);
      expect(taps, 1);
      final hold = await tester.startGesture(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selections, 0);
      await tester.pump(const Duration(milliseconds: 110));
      expect(selections, 1);
      await hold.up();
      await tester.pump();
      expect(selections, 1);
      expect(taps, 1);
    },
  );

  testWidgets('page swipe cancels verse selection', (tester) async {
    var selections = 0;
    var drags = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GestureDetector(
          onHorizontalDragUpdate: (_) => drags++,
          child: Center(
            child: AyahPressTarget(
              onSelected: () => selections++,
              child: const SizedBox(width: 200, height: 60, child: Text('آية')),
            ),
          ),
        ),
      ),
    );
    final drag = await tester.startGesture(
      tester.getCenter(find.byType(AyahPressTarget)),
    );
    await drag.moveBy(const Offset(70, 0));
    await drag.moveBy(const Offset(20, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await drag.up();
    expect(selections, 0);
    expect(drags, greaterThan(0));
  });
}
