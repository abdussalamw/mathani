
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/mushaf_metadata_provider.dart';

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

  void _showMushafPicker(BuildContext context, MushafMetadataProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // ارتفاع مناسب (60% من الشاشة)
        ),
        child: Column(
          children: [
            // المقبض العلوي
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            
            Text(
              'اختر طبعة المصحف',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تحميل طبعات إضافية عالية الجودة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // القائمة
            Expanded(
              child: ListView.separated(
                itemCount: provider.availableMushafs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final mushaf = provider.availableMushafs[index];
                  final isSelected = mushaf.identifier == provider.currentMushafId;
                  final isDownloadingThis = provider.isDownloading && provider.currentDownloadingId == mushaf.identifier;
                  final needsDownload = !mushaf.isDownloaded && mushaf.baseUrl != null;
                  
                  // تصميم البطاقة
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.05) 
                          : Theme.of(context).cardColor,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // الأيقونة
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            mushaf.type.contains('font') ? Icons.text_fields : Icons.menu_book,
                            color: isSelected ? Colors.white : AppColors.darkBrown,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // النصوص
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mushaf.nameArabic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mushaf.type.contains('font') ? 'نص رقمي (سريع)' : 'خطوط الرسم العثماني (QCF)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (isDownloadingThis) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: provider.downloadProgress, 
                                  backgroundColor: Colors.grey[200],
                                  color: AppColors.primary,
                                  minHeight: 4,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'جاري التحميل ${(provider.downloadProgress * 100).toInt()}%',
                                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                                ),
                              ]
                            ],
                          ),
                        ),
                        
                        // زر الإجراء (Action Button)
                        const SizedBox(width: 8),
                        if (isSelected) 
                          // حالة: مفعل
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text('مفعل', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )
                        else if (needsDownload)
                           // حالة: يحتاج تحميل
                           isDownloadingThis 
                             ? const SizedBox() // يظهر شريط التقدم في الأسفل
                             : ElevatedButton.icon(
                                 onPressed: () => provider.downloadMushaf(mushaf.identifier),
                                 icon: const Icon(Icons.download, size: 16),
                                 label: const Text('تنزيل'),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.grey[100],
                                   foregroundColor: Colors.black87,
                                   elevation: 0,
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 ),
                               )
                        else 
                           // حالة: محمل وجاهز للتفعيل
                           ElevatedButton(
                             onPressed: () {
                               provider.setMushaf(mushaf.identifier);
                               Navigator.pop(context);
                             },
                             child: const Text('تفعيل'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.primary,
                               foregroundColor: Colors.white,
                               elevation: 0,
                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                             ),
                           ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
