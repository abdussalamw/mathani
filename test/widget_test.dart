import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathani_quran/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MathaniApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that the app builds without crashing and navigates
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
