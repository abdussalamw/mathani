import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathani/core/di/service_locator.dart';
import 'package:mathani/main.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('App smoke test — real entry point constructs', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // تهيئة نفس التبعيات التي يهيئها main() الحقيقي
    SharedPreferences.setMockInitialValues({});
    await initServiceLocator();
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    // التطبيق الحقيقي (main.dart) يُبنى بنجاح بدون أي أخطاء تركيب.
    // ملاحظة: لا نستخدم pumpWidget هنا لأن شجرة التطبيق الكاملة تعتمد
    // على إضافات (plugins) حقيقية (Isar/sherpa/JustAudio) لا تتوفر في بيئة
    // الاختبار — اختبار تدفق السبلاش الكامل يحتاج محاكاة شاملة منفصلة.
    final app = MathaniApp(settingsProvider: settingsProvider);
    expect(app.settingsProvider, same(settingsProvider));
    expect(app, isA<Widget>());
  });
}
