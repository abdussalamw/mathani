
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/mushaf_metadata_provider.dart';
import 'mushaf_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // قسم المظهر
              _buildSectionHeader(context, 'المظهر'),
              _buildSettingCard(
                context,
                icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                title: 'الوضع الليلي',
                subtitle: settings.isDarkMode ? 'مفعل' : 'معطل',
                trailing: Switch.adaptive(
                  value: settings.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (value) => settings.toggleTheme(),
                ),
              ),
              const SizedBox(height: 16),
              
              // حجم الخط
               _buildSettingCard(
                context,
                icon: Icons.format_size,
                title: 'حجم خط المصحف',
                subtitle: '${settings.fontSize.toInt()} بكسل',
                child: Column(
                  children: [
                    Slider(
                      value: settings.fontSize,
                      min: 20,
                      max: 48,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.greyLight,
                      onChanged: (value) => settings.updateFontSize(value),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: settings.fontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // قسم المصحف
              _buildSectionHeader(context, 'نسخة المصحف'),
              Consumer<MushafMetadataProvider>(
                builder: (context, mushafProvider, _) {
                  if (mushafProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final currentMushaf = mushafProvider.availableMushafs.firstWhere(
                    (m) => m.identifier == mushafProvider.currentMushafId,
                    orElse: () => mushafProvider.availableMushafs.first,
                  );

                  return _buildSettingCard(
                    context,
                    icon: Icons.book,
                    title: 'المصحف المختار',
                    subtitle: currentMushaf.nameArabic,
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyMedium),
                    onTap: () => _showMushafPicker(context, mushafProvider),
                  );
                },
              ),
              const SizedBox(height: 16),

              // قسم القراءة
              _buildSectionHeader(context, 'القراءة والتلاوة'),
              _buildSettingCard(
                context,
                icon: Icons.record_voice_over,
                title: 'القارئ الافتراضي',
                subtitle: _getReciterName(settings.defaultReciter),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyMedium),
                onTap: () {
                  // Show Reciter Picker Sheet
                  _showReciterPicker(context, settings);
                },
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.menu_book,
                title: 'التفسير الافتراضي',
                subtitle: _getTafsirName(settings.defaultTafsir),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyMedium),
                onTap: () {
                  // Show Tafsir Picker
                  _showTafsirPicker(context, settings);
                },
              ),
              
              const SizedBox(height: 32),

              // قسم التطبيق
              _buildSectionHeader(context, 'عن التطبيق'),
              _buildSettingCard(
                context,
                icon: Icons.info_outline,
                title: 'حول مثاني',
                subtitle: 'الإصدار 1.0.0',
                onTap: () {
                  // Show About Dialog
                },
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                icon: Icons.share,
                title: 'مشاركة التطبيق',
                subtitle: 'شارك الأجر مع أصدقائك',
                onTap: () {
                  // Share implementation relative
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: 16),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getReciterName(String id) {
    // Map IDs to Names
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
      case 'baghawy': return 'تفسير البغوي';
      default: return 'التفسير الميسر';
    }
  }

  void _showReciterPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر القارئ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildRadioOption(context, 'محمد صديق المنشاوي', 'minshawi_murattal', settings.defaultReciter, (val) {
              settings.updateDefaultReciter(val!); // You need to implement this method in Provider
              Navigator.pop(context);
            }),
            _buildRadioOption(context, 'مشاري العفاسي', 'alafasy', settings.defaultReciter, (val) {
              settings.updateDefaultReciter(val!);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showTafsirPicker(BuildContext context, SettingsProvider settings) {
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(
              'اختر التفسير',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildRadioOption(context, 'التفسير الميسر', 'muyassar', settings.defaultTafsir, (val) {
              settings.updateDefaultTafsir(val!); // Implement in Provider
              Navigator.pop(context);
            }),
            _buildRadioOption(context, 'تفسير السعدي', 'saadi', settings.defaultTafsir, (val) {
              settings.updateDefaultTafsir(val!);
               Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(BuildContext context, String label, String value, String groupValue, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

// Import the new screen at the top of file (I will handle imports carefully via multi-edit or assume it resolves if I could edit imports, but simplest is to just navigate)
  // Since I cannot scroll to top to add import easily in Replace, I will rely on the user or context.
  // Actually, I can navigate using MaterialPageRoute directly with the widget I just created.
  
  // Update the call site first
  // ...
  
  // The method implementation:
  void _showMushafPicker(BuildContext context, MushafMetadataProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MushafSelectionScreen()),
    );
  }
} // End of class
