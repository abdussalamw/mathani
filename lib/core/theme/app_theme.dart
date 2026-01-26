import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
      onPrimary: AppColors.white,
      onSecondary: AppColors.darkBrown,
      error: Colors.red,
    ),
    
    textTheme: TextTheme(
      // العناوين الكبيرة
      displayLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
      
      // العناوين المتوسطة
      headlineLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
      
      // النصوص العادية
      bodyLarge: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 28,
        color: AppColors.darkBrown,
        height: 2.2,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: AppColors.darkBrown,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        color: AppColors.greyDark,
      ),
      
      // التسميات
      labelLarge: TextStyle(
        fontFamily: 'Tajawal',
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
    
    cardTheme: CardThemeData(
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
      onPrimary: AppColors.white,
      onSecondary: AppColors.darkText,
      error: Colors.red,
    ),
    
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 28,
        color: AppColors.darkText,
        height: 2.2,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: AppColors.darkText,
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.darkSurface,
    ),
  );
}
