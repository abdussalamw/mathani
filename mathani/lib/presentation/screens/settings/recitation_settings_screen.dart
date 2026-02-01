import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

class RecitationSettingsScreen extends StatelessWidget {
  const RecitationSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'إعدادات التلاوة',
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
            title: 'القارئ',
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: [
                    _buildReciterTile(
                      context,
                      name: 'مشاري راشد العفاسي',
                      value: 'alafasy',
                      groupValue: settings.defaultReciter,
                      onChanged: (val) => settings.updateDefaultReciter(val!),
                    ),
                    const Divider(height: 1),
                    _buildReciterTile(
                      context,
                      name: 'عبد الباسط عبد الصمد',
                      value: 'abdulbasit',
                      groupValue: settings.defaultReciter,
                      onChanged: (val) => settings.updateDefaultReciter(val!),
                    ),
                    const Divider(height: 1),
                    _buildReciterTile(
                      context,
                      name: 'محمد صديق المنشاوي',
                      value: 'minshawi_murattal',
                      groupValue: settings.defaultReciter,
                      onChanged: (val) => settings.updateDefaultReciter(val!),
                    ),
                    const Divider(height: 1),
                    _buildReciterTile(
                      context,
                      name: 'السديس والشريم',
                      value: 'sudais',
                      groupValue: settings.defaultReciter,
                      onChanged: (val) => settings.updateDefaultReciter(val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'خيارات التشغيل',
            children: [
              ListTile(
                leading: Icon(Icons.high_quality, color: Colors.blue),
                title: const Text(
                  'جودة الصوت',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                subtitle: const Text(
                  '128 kbps',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Quality selection
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

  Widget _buildReciterTile(
    BuildContext context, {
    required String name,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(
        name,
        style: const TextStyle(fontFamily: 'Tajawal'),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
