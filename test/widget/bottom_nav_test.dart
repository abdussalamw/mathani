import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mathani/presentation/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('exposes the selected destination and reports the tapped tab', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 2,
            onTap: (i) => selected = i,
          ),
        ),
      ),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    await tester.tap(find.text('الفهرس'));
    expect(selected, 0);
  });
}
