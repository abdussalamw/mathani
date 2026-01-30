import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

import 'core/database/isar_service.dart';
import 'core/database/collections.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';


import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/quran_provider.dart';
import 'presentation/providers/mushaf_metadata_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/home/main_shell_screen.dart';
import 'presentation/screens/mushaf/mushaf_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات
  await IsarService.instance.init();
  
  // تهيئة حقن التبعيات
  await initServiceLocator();
  

  
  final isar = IsarService.instance.isar;
  
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

class MathaniApp extends StatelessWidget {
  const MathaniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => MushafMetadataProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'مثاني - القرآن الكريم',
            debugShowCheckedModeBanner: false,
            // Custom Theme Data if AppTheme is not fully ready or defined elsewhere, 
            // but relying on imports for now.
             theme: AppTheme.lightTheme,
             darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // الصفحة الأولى حسب حالة الخطوط
            home: const SplashScreen(),
            
            routes: {
              '/home': (context) => const MainShellScreen(),
              '/mushaf': (context) => const MushafScreen(),
            },
          );
        },
      ),
    );
  }
}
