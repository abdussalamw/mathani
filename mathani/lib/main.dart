import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/database/isar_service.dart';
import 'core/database/collections.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';


import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/quran_provider.dart';
import 'presentation/providers/mushaf_metadata_provider.dart';
import 'data/providers/mushaf_navigation_provider.dart';
import 'presentation/providers/audio_provider.dart'; // Add import
import 'package:mathani/presentation/providers/bookmark_provider.dart';
import 'presentation/providers/surah_content_provider.dart';
import 'presentation/providers/ui_provider.dart';
import 'presentation/providers/tafsir_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/home/main_shell_screen.dart';
import 'presentation/screens/mushaf/mushaf_screen.dart';
import 'presentation/screens/test/font_test_screen.dart';
import 'presentation/screens/startup/initial_download_screen.dart';




import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('Failed to initialize JustAudioBackground: $e');
  }
  
  try {
    // تهيئة قاعدة البيانات
    if (!kIsWeb) {
      await IsarService.instance.init();
    }
    
    // تهيئة حقن التبعيات
    await initServiceLocator();
    
    // إعداد افتراضي
    if (!kIsWeb) {
      try {
        final isar = IsarService.instance.isar;
        
        await isar.writeTxn(() async {
          final count = await isar.collection<UserSettings>().count();
          if (count == 0) {
            await isar.collection<UserSettings>().put(
              UserSettings()..selectedMushafId = 'madani_font_v1'
            );
          }
        });
      } catch (e) {
        debugPrint('Error initializing default settings: $e');
        // Continue anyway - settings will use defaults
      }
    }
    
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
    
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();
    
    runApp(MathaniApp(settingsProvider: settingsProvider));
  } catch (e, stackTrace) {
    debugPrint('CRITICAL ERROR in main(): $e');
    debugPrint('Stack trace: $stackTrace');
    // Pass error to app
    runApp(MathaniApp(initializationError: e.toString()));
  }
}

class MathaniApp extends StatelessWidget {
  final String? initializationError;
  final SettingsProvider? settingsProvider;

  const MathaniApp({
    Key? key,
    this.initializationError,
    this.settingsProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If initialization failed, show error immediately
    if (initializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'فشل تهيئة التطبيق',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        initializationError!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontFamily: 'monospace'),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: initializationError!));
                    },
                    child: const Text('نسخ تفاصيل الخطأ', style: TextStyle(fontFamily: 'Tajawal')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider ?? SettingsProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => MushafMetadataProvider()),
        ChangeNotifierProxyProvider<MushafMetadataProvider, MushafNavigationProvider>(
          create: (_) => MushafNavigationProvider(),
          update: (_, metadata, navigation) {
            navigation!.updateMushaf(metadata.currentMushafId);
            return navigation;
          },
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => SurahContentProvider()), // Added
        ChangeNotifierProvider(create: (_) => UiProvider()),
        ChangeNotifierProvider(create: (_) => TafsirProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'مثاني - القرآن الكريم',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Localization Setup
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'), // Arabic is default
              Locale('en'),
            ],
            locale: const Locale('ar'),
            
            // Error handling
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 80, color: Colors.red),
                          const SizedBox(height: 24),
                          const Text(
                            'حدث خطأ في التطبيق',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorDetails.exception.toString(),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              return widget!;
            },
            
            // الصفحة الأولى حسب حالة الخطوط
            home: const SplashScreen(),
            
            routes: {
              '/home': (context) => const MainShellScreen(),
              '/mushaf': (context) => const MushafScreen(),
              '/font-test': (context) => const FontTestScreen(),
              '/initial_download': (context) => const InitialDownloadScreen(),
            },
          );
        },
      ),
    );
  }
}
