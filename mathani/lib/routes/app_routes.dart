import 'package:flutter/material.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/home/main_shell_screen.dart';
import '../presentation/screens/surah_list/surah_list_screen.dart';
import '../presentation/screens/mushaf/mushaf_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String surahList = '/surah-list';
  static const String mushaf = '/mushaf';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    home: (context) => const MainShellScreen(),
    surahList: (context) => const SurahListScreen(),
    mushaf: (context) => const MushafScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
