import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/navigation_controller.dart';
import 'presentation/providers/quran_provider.dart';
import 'presentation/providers/audio_provider.dart';
import 'presentation/providers/mushaf_metadata_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'routes/app_routes.dart';
import 'presentation/screens/splash/splash_screen.dart';

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
            navigatorKey: NavigationController.navigatorKey,
            title: 'Mathani - مثاني - القرآن الكريم',
            debugShowCheckedModeBanner: false,
            
            // الثيم
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // اللغة
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
            
            // التوجيه
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            // home: const SplashScreen(), // مستبدل بـ initialRoute
          );
        },
      ),
    );
  }
}
