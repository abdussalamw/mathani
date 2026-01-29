import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B7355),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF8F3),
    fontFamily: 'Tajawal',
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B7355),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    fontFamily: 'Tajawal',
  );
}
