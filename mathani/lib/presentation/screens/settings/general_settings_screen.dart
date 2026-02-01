import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'الإعدادات العامة',
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
          _buildSection(
            context,
            title: 'المظهر',
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => SwitchListTile(
                  title: const Text(
                    'الوضع الليلي',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  subtitle: const Text(
                    'تفعيل الوضع الداكن',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                  ),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: Colors.purple,
                  ),
                  value: settings.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (_) => settings.toggleDarkMode(),
                ),
              ),
              const Divider(height: 1),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.format_size, color: Colors.blue),
                      title: const Text(
                        'حجم الخط',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      trailing: Text(
                        '${settings.fontSize.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: settings.fontSize,
                        min: 20,
                        max: 48,
                        divisions: 14,
                        activeColor: AppColors.primary,
                        onChanged: (val) => settings.setFontSize(val),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: settings.fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'عام',
            children: [
              ListTile(
                leading: Icon(Icons.language, color: Colors.orange),
                title: const Text(
                  'اللغة',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                subtitle: const Text(
                  'العربية',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Language selection
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.green),
                title: const Text(
                  'حول التطبيق',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'مثاني',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'اللَّهُ نَزَّلَ أَحْسَنَ الْحَدِيثِ كِتَابًا مُّتَشَابِهًا مَّثَانِيَ',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF2C2416) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 1,
          child: Column(children: children),
        ),
      ],
    );
  }
}
