import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TafsirSettingsScreen extends StatelessWidget {
  const TafsirSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'إعدادات التفاسير',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'قريباً إن شاء الله',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'سيتم إضافة التفاسير والترجمات في التحديثات القادمة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
