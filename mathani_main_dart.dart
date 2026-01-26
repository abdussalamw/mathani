// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/database/isar_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'providers/quran_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/mushaf_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات
  await IsarService.instance.init();
  
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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'مثاني - القرآن الكريم',
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
            
            // الشاشة الرئيسية
            home: const SplashScreen(),
            
            // المسارات
            routes: {
              '/mushaf': (context) => const MushafScreen(),
            },
          );
        },
      ),
    );
  }
}

// lib/core/constants/app_colors.dart
class AppColors {
  // الألوان الأساسية
  static const Color primary = Color(0xFFE30613); // أحمر نسكافيه
  static const Color golden = Color(0xFFD4AF37); // ذهبي
  static const Color darkBrown = Color(0xFF2C1810); // نصوص القرآن
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFDF6E3);
  
  // الوضع الليلي
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFE8E8E8);
  
  // ألوان إضافية
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);
  
  // ألوان التجويد (للميزات المتقدمة)
  static const Color idgham = Color(0xFF4CAF50); // إدغام
  static const Color ikhfa = Color(0xFFFFEB3B); // إخفاء
  static const Color qalqala = Color(0xFFF44336); // قلقلة
  static const Color madd = Color(0xFF2196F3); // مد
  static const Color ghunna = Color(0xFFE91E63); // غنة
}

// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.golden,
      surface: AppColors.white,
      background: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.darkBrown,
      error: Colors.red,
    ),
    
    textTheme: TextTheme(
      // العناوين الكبيرة
      displayLarge: GoogleFonts.tajawal(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
      displayMedium: GoogleFonts.tajawal(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
      
      // العناوين المتوسطة
      headlineLarge: GoogleFonts.tajawal(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
      headlineMedium: GoogleFonts.tajawal(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
      
      // النصوص العادية
      bodyLarge: GoogleFonts.amiri(
        fontSize: 28,
        color: AppColors.darkBrown,
        height: 2.2,
      ),
      bodyMedium: GoogleFonts.tajawal(
        fontSize: 16,
        color: AppColors.darkBrown,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.tajawal(
        fontSize: 14,
        color: AppColors.greyDark,
      ),
      
      // التسميات
      labelLarge: GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkBrown,
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkBrown),
      titleTextStyle: TextStyle(
        color: AppColors.darkBrown,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
      ),
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.white,
    ),
    
    iconTheme: const IconThemeData(
      color: AppColors.darkBrown,
      size: 24,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.golden,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      onPrimary: AppColors.white,
      onSecondary: AppColors.darkText,
      error: Colors.red,
    ),
    
    textTheme: TextTheme(
      displayLarge: GoogleFonts.tajawal(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      displayMedium: GoogleFonts.tajawal(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      headlineLarge: GoogleFonts.tajawal(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyLarge: GoogleFonts.amiri(
        fontSize: 28,
        color: AppColors.darkText,
        height: 2.2,
      ),
      bodyMedium: GoogleFonts.tajawal(
        fontSize: 16,
        color: AppColors.darkText,
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.darkSurface,
    ),
  );
}

// lib/screens/splash_screen.dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
    
    _navigateToHome();
  }
  
  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/mushaf');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.golden.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'مَثَانِي',
                      style: GoogleFonts.amiri(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // الوصف
                Text(
                  'القرآن الكريم',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    color: AppColors.darkBrown.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // مؤشر التحميل
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}