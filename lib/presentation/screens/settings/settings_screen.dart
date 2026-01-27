
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../mushaf/mushaf_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SettingsProvider, bool>((s) => s.isDarkMode);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6), // خلفية رمادية فاتحة عصرية
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // قسم المظهر
          _buildSectionTitle(context, 'المظهر والخطوط'),
          _buildSettingsGroup(
            context,
            children: [
              _buildSwitchTile(
                context,
                icon: Icons.dark_mode_outlined,
                color: Colors.purple,
                title: 'الوضع الليلي',
                value: isDark,
                onChanged: (val) => context.read<SettingsProvider>().toggleTheme(),
              ),
              _buildDivider(),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildIconBox(Icons.format_size, Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'حجم الخط',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('${settings.fontSize.toInt()}', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Slider(
                      value: settings.fontSize,
                      min: 20,
                      max: 48,
                      activeColor: AppColors.primary,
                      onChanged: (val) => settings.updateFontSize(val),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        style: TextStyle(fontFamily: 'Amiri', fontSize: settings.fontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // قسم الصوتيات والتلاوة
          _buildSectionTitle(context, 'التلاوة والاستماع'),
          _buildSettingsGroup(
            context,
            children: [
               Consumer<SettingsProvider>(
                 builder: (context, settings, _) => _buildNavigationTile(
                  context,
                  icon: Icons.record_voice_over_outlined,
                  color: Colors.orange,
                  title: 'القارئ المفضل',
                  subtitle: _getReciterName(settings.defaultReciter),
                  onTap: () => _showReciterPicker(context, settings),
                ),
               ),
              _buildDivider(),
              Consumer<SettingsProvider>(
                 builder: (context, settings, _) => _buildNavigationTile(
                  context,
                  icon: Icons.library_books_outlined,
                  color: Colors.teal,
                  title: 'مرجع التفسير',
                  subtitle: _getTafsirName(settings.defaultTafsir),
                  onTap: () => _showTafsirPicker(context, settings),
                ),
               ),
            ],
          ),

          const SizedBox(height: 24),

          // قسم التطبيق
          _buildSectionTitle(context, 'عن التطبيق'),
          _buildSettingsGroup(
            context,
            children: [
              _buildNavigationTile(
                context,
                icon: Icons.info_outline,
                color: Colors.grey,
                title: 'حول مثاني',
                subtitle: 'الإصدار 1.0.0',
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationTile(
                context,
                icon: Icons.share_outlined,
                color: Colors.green,
                title: 'شارك التطبيق',
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Helper Widgets for Modern UI ---

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildIconBox(icon, color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIconBox(icon, color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, indent: 60, color: Colors.grey[200]);
  }

  String _getReciterName(String id) {
     switch (id) {
      case 'minshawi_murattal': return 'محمد صديق المنشاوي';
      case 'alafasy': return 'مشاري العفاسي';
      default: return 'محمد صديق المنشاوي';
    }
  }

  String _getTafsirName(String id) {
    switch (id) {
      case 'muyassar': return 'التفسير الميسر';
      case 'saadi': return 'تفسير السعدي';
      default: return 'التفسير الميسر';
    }
  }

  // Simplified Pickers for Reciter/Tafsir (kept from old code logic but styled a bit)
  void _showReciterPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
         padding: const EdgeInsets.all(24),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('اختر القارئ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 16),
             _buildRadioItem(context, 'محمد صديق المنشاوي', 'minshawi_murattal', settings.defaultReciter, (v) {
               settings.updateDefaultReciter(v!);
               Navigator.pop(context);
             }),
             _buildRadioItem(context, 'مشاري العفاسي', 'alafasy', settings.defaultReciter, (v) {
               settings.updateDefaultReciter(v!);
               Navigator.pop(context);
             }),
           ]
         )
      )
    );
  }

  void _showTafsirPicker(BuildContext context, SettingsProvider settings) {
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
         padding: const EdgeInsets.all(24),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('اختر التفسير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 16),
             _buildRadioItem(context, 'التفسير الميسر', 'muyassar', settings.defaultTafsir, (v) {
               settings.updateDefaultTafsir(v!);
               Navigator.pop(context);
             }),
             _buildRadioItem(context, 'تفسير السعدي', 'saadi', settings.defaultTafsir, (v) {
               settings.updateDefaultTafsir(v!);
               Navigator.pop(context);
             }),
             _buildRadioItem(context, 'تفسير البغوي', 'baghawy', settings.defaultTafsir, (v) {
               settings.updateDefaultTafsir(v!);
               Navigator.pop(context);
             }),
           ]
         )
      )
    );
  }
  
  Widget _buildRadioItem(BuildContext context, String label, String value, String groupValue, Function(String?) onChanged) {
    return RadioListTile(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
