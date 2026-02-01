import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'general_settings_screen.dart';
import 'mushaf_settings_screen.dart';
import 'tafsir_settings_screen.dart';
import 'recitation_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            context,
            title: 'عام',
            subtitle: 'المظهر، اللغة، والإعدادات العامة',
            icon: Icons.settings,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            title: 'المصاحف',
            subtitle: 'إدارة المصاحف المحملة والمتاحة',
            icon: Icons.menu_book,
            color: AppColors.golden,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MushafSettingsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            title: 'التفاسير',
            subtitle: 'إدارة التفاسير والترجمات',
            icon: Icons.library_books,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TafsirSettingsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            title: 'التلاوات',
            subtitle: 'القراء والتلاوات الصوتية',
            icon: Icons.headphones,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecitationSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF2C2416) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
