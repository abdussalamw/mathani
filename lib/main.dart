import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import 'app.dart';
import 'core/database/isar_service.dart';
import 'core/database/collections.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات
  final isarService = IsarService.instance;
  await isarService.init();
  final isar = await isarService.db;
  
  // إعداد افتراضي
  await isar.writeTxn(() async {
    final count = await isar.collection<UserSettings>().count();
    if (count == 0) await isar.collection<UserSettings>().put(UserSettings()..selectedMushafId = 'madani_font_v1');
  });
  
  // إعدادات النظام
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MathaniApp());
}
