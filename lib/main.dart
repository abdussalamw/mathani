import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/database/isar_service.dart';
import 'core/database/collections.dart';
import 'core/utils/navigation_controller.dart';
import 'core/theme/app_theme.dart';
import 'providers/quran_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/mushaf_metadata_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/mushaf_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/surah_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات
  final isarService = IsarService.instance;
  await isarService.init(); // التأكد من اكتمال الفتح قبل المتابعة
  final isar = await isarService.db;
  
  // تأكد من وجود إعدادات ابتدائية لضمان عمل الـ Providers
  await isar.writeTxn(() async {
    final count = await isar.collection<UserSettings>().count();
    if (count == 0) await isar.collection<UserSettings>().put(UserSettings()..selectedMushafId = 'madani_font_v1');
  });
  
  // قفل الاتجاه على الوضع العمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تخصيص شريط الحالة
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
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => MushafMetadataProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: NavigationController.navigatorKey, // مفتاح التحكم بالتنقل
            title: 'Mathani - مثاني - القرآن الكريم',
            debugShowCheckedModeBanner: false,
            
            // الثيم
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // اللغة والاتجاه
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // الشاشة الرئيسية
            home: const SplashScreen(),
            
            // المسارات
            routes: {
              '/mushaf': (context) => const MushafScreen(),
              '/surah-list': (context) => const SurahListScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/home': (context) => const MainShellScreen(),
            },
          );
        },
      ),
    );
  }
}
