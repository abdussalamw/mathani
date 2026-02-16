import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/models/reciter.dart';
import '../../../core/database/collections.dart'; // Needed for MushafMetadata

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    // Use a ListView directly - no Scaffold/AppBar needed if embedded in MainShell
    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      child: ListView(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 60, bottom: 12),
        children: [
          // 1. المظهر (Compact)
          _buildSectionTitle(context, 'المظهر'),
          const SizedBox(height: 8),
          
          // Theme Toggle Row
          Container(
             padding: const EdgeInsets.all(2),
             decoration: BoxDecoration(
               color: isDark ? Colors.grey[800] : Colors.grey[200],
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               children: [
                  Expanded(child: _CompactThemeButton(title: 'فاتح', icon: Icons.wb_sunny, isSelected: !isDark, onTap: () => settings.setDarkMode(false))),
                  Expanded(child: _CompactThemeButton(title: 'داكن', icon: Icons.nightlight_round, isSelected: isDark, onTap: () => settings.setDarkMode(true))),
               ],
             ),
          ),
          
          if (!isDark) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompactColorOption('أبيض', 'white', Colors.white, settings.backgroundColorMode, (v) => settings.setBackgroundColorMode(v)),
                _CompactColorOption('كريمي', 'cream', const Color(0xFFFFFDD0), settings.backgroundColorMode, (v) => settings.setBackgroundColorMode(v)),
                _CompactColorOption('ورق', 'old', const Color(0xFFF3E5AB), settings.backgroundColorMode, (v) => settings.setBackgroundColorMode(v)),
              ],
            ),
          ],
          
          const Divider(height: 24),

          // 2. المحتوى (Compact + Dual Buttons)
          _buildSectionTitle(context, 'المحتوى'),
          const SizedBox(height: 8),

          // Mushafs
          _CompactExpandableCard(
            title: 'المصحف',
            subtitle: context.read<MushafMetadataProvider>().availableMushafs
                .firstWhere((m) => m.identifier == context.read<MushafMetadataProvider>().currentMushafId, 
                    orElse: () => context.read<MushafMetadataProvider>().availableMushafs.first).nameArabic ?? 'اختر المصحف',
            icon: Icons.menu_book,
            color: AppColors.golden,
            children: [
              Consumer<MushafMetadataProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: provider.availableMushafs.map<Widget>((MushafMetadata mushaf) {
                      final isSelected = provider.currentMushafId == mushaf.identifier;
                      final isDownloaded = mushaf.isDownloaded || mushaf.type == 'font_v2' || mushaf.type == 'digital';
                      
                      return _CompactSettingItem(
                        title: mushaf.nameArabic ?? '',
                        isSelected: isSelected,
                        isDownloaded: isDownloaded,
                        onActivate: () => provider.setMushaf(mushaf.identifier!),
                        onDownload: () => provider.downloadMushaf(mushaf.identifier!),
                      );
                    }).toList(),
                  );
                },
              )
            ],
          ),
          
          const SizedBox(height: 8),

          // Tafsir
          _CompactExpandableCard(
            title: 'التفسير',
            subtitle: settings.defaultTafsir == 'muyassar' ? 'التفسير الميسر' : settings.defaultTafsir,
            icon: Icons.library_books,
            color: Colors.green,
            children: [
               ...[
                 {'id': 'w-moyassar', 'name': 'التفسير الميسر'},
                 {'id': 'tafsir-katheer', 'name': 'تفسير ابن كثير'},
                 {'id': 'tafsir-saadi', 'name': 'تفسير السعدي'},
                 {'id': 'tafsir-baghawy', 'name': 'تفسير البغوي'},
                 {'id': 'tafsir-tabary', 'name': 'تفسير الطبري'},
                 {'id': 'eerab-aya', 'name': 'إعراب القرآن'},
                 // {'id': 'ayat-nozool', 'name': 'أسباب النزول'}, // Optional: removed based on reliability check? User didn't ask to remove it explicitly but reliability was 404. Let's keep it for now as "Conditional".
               ].map((tafsir) {
                 final isSelected = settings.defaultTafsir == tafsir['id'];
                 return _CompactSettingItem(
                   title: tafsir['name']!,
                   isSelected: isSelected,
                   isDownloaded: true, // Always available (Online)
                   onActivate: () => context.read<SettingsProvider>().updateDefaultTafsir(tafsir['id']!),
                   onDownload: () {
                     // Placeholder for offline caching future
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('متاح عبر الإنترنت حالياً', style: TextStyle(fontFamily: 'Tajawal')))); 
                   },
                 );
               }).toList(),
            ],
          ),

          const SizedBox(height: 8),

          // Audio
          _CompactExpandableCard(
            title: 'الصوت',
            subtitle: context.read<AudioProvider>().reciters.firstWhere((r) => r.id == settings.defaultReciter, orElse: () => Reciter(id: '', name: 'اختر القارئ', style: '', bitrate: '')).name,
            icon: Icons.headphones,
            color: Colors.purple,
            children: [
               Consumer<AudioProvider>(
                 builder: (context, audio, _) {
                   return Column(
                     children: audio.reciters.map((reciter) {
                       final isSelected = settings.defaultReciter == reciter.id;
                       return _CompactSettingItem(
                         title: reciter.name,
                         isSelected: isSelected,
                         isDownloaded: true, // Streaming default
                         onActivate: () {
                           context.read<SettingsProvider>().updateDefaultReciter(reciter.id);
                           context.read<AudioProvider>().setReciter(reciter);
                         },
                         onDownload: () {
                            // Future: Download Manager
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('التحميل قادم قريباً', style: TextStyle(fontFamily: 'Tajawal'))));
                         },
                       );
                     }).toList(),
                   );
                 },
               )
            ],
          ),

          const Divider(height: 24),

          // 3. Footer (Very Compact)
          Center(
            child: Text('مثاني v$_version', style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Colors.grey[600])),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12, // Reduced from 16
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// --- Compact Widgets ---

class _CompactThemeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactThemeButton({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 12
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 16), // Reduced size
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CompactColorOption extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String currentValue;
  final Function(String) onSelect;

  const _CompactColorOption(this.label, this.value, this.color, this.currentValue, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Row(
        children: [
           Container(
             width: 24, // Reduced from 50
             height: 24,
             decoration: BoxDecoration(
               color: color,
               shape: BoxShape.circle,
               border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: isSelected ? 2 : 1),
             ),
             child: isSelected ? const Icon(Icons.check, size: 14, color: AppColors.primary) : null,
           ),
           const SizedBox(width: 6),
           Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _CompactExpandableCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _CompactExpandableCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF2C2416) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0.5,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(6), // Reduced
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18), // Reduced
          ),
          title: Text(title, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          children: children,
        ),
      ),
    );
  }
}

class _CompactSettingItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDownloaded;
  final VoidCallback onActivate;
  final VoidCallback onDownload;

  const _CompactSettingItem({
    required this.title,
    required this.isSelected,
    required this.isDownloaded,
    required this.onActivate,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Download Button
              if (!isDownloaded)
                InkWell(
                  onTap: onDownload,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.download_rounded, size: 16, color: Colors.black54),
                  ),
                )
              else 
                 const Icon(Icons.check_circle_outline, size: 16, color: Colors.green), // Visual indicator of readiness
              
              const SizedBox(width: 8),
              
              // Activate Button
              InkWell(
                onTap: onActivate,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSelected ? 'مفعل' : 'تفعيل',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
