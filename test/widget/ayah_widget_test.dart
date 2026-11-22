import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/presentation/widgets/ayah_press_target.dart';

void main() {
  testWidgets(
    'a nonselectable verse keeps its text and surrounding tap action',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GestureDetector(
            onTap: () => taps++,
            child: const Center(child: AyahPressTarget(child: Text('الآية'))),
          ),
        ),
      );
      await tester.tap(find.text('الآية'));
      expect(taps, 1);
    },
  );
}
