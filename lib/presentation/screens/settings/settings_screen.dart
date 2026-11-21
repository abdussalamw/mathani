import '../../widgets/download_feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../core/constants/app_colors.dart';

import '../../../data/models/reciter.dart';
import '../../../data/services/local_tafsir_service.dart';
import '../../../core/database/collections.dart'; // Needed for MushafMetadata
import '../../../l10n/app_localizations.dart';
import 'recitation_diagnostic_screen.dart';
import '../recitation/recitation_screen.dart';
import '../../providers/recitation_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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

  void _loadVersion() {
    setState(() {
      _version = '1.0.2';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    // Use a ListView directly - no Scaffold/AppBar needed if embedded in MainShell
    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: ListView(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          bottom: 120,
        ),
        children: [
          // 0. مركز التحميل
          _buildDownloadCenterLink(context, isDark),

          const SizedBox(height: 8),

          // 0b. تشخيص نظام التسميع
          _buildDiagnosticLink(context, isDark),

          const SizedBox(height: 8),

          // 0c. إعدادات التسميع
          _buildRecitationSettingsLink(context, isDark),

          const SizedBox(height: 16),

          // 1. الإعدادات العامة (اللغة والمظهر)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandGold.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                // اللغة (Language)
                _buildInlineSettingRow(
                  context,
                  AppLocalizations.of(context)!.language,
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactThemeButton(
                            title: 'العربية',
                            isSelected: settings.localeCode == 'ar',
                            onTap: () => settings.setLanguage('ar'),
                          ),
                        ),
                        Expanded(
                          child: _CompactThemeButton(
                            title: 'English',
                            isSelected: settings.localeCode == 'en',
                            onTap: () => settings.setLanguage('en'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 16),

                // المظهر (Appearance)
                _buildInlineSettingRow(
                  context,
                  AppLocalizations.of(context)!.appearance,
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactThemeButton(
                            title: AppLocalizations.of(context)!.lightMode,
                            icon: Icons.wb_sunny,
                            isSelected: !isDark,
                            onTap: () => settings.setDarkMode(false),
                          ),
                        ),
                        Expanded(
                          child: _CompactThemeButton(
                            title: AppLocalizations.of(context)!.darkMode,
                            icon: Icons.nightlight_round,
                            isSelected: isDark,
                            onTap: () => settings.setDarkMode(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // 2. المحتوى (Compact + Dual Buttons)
          _buildSectionTitle(
            context,
            AppLocalizations.of(context)!.settingsMushafs,
          ),
          const SizedBox(height: 8),

          // Mushafs
          _CompactExpandableCard(
            title: AppLocalizations.of(context)!.mushaf,
            subtitle:
                context
                    .read<MushafMetadataProvider>()
                    .availableMushafs
                    .firstWhere(
                      (m) =>
                          m.identifier ==
                          context
                              .read<MushafMetadataProvider>()
                              .currentMushafId,
                      orElse: () => context
                          .read<MushafMetadataProvider>()
                          .availableMushafs
                          .first,
                    )
                    .nameArabic ??
                '',
            icon: Icons.menu_book,
            color: AppColors.golden,
            children: [
              Consumer<MushafMetadataProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: provider.availableMushafs.map<Widget>((
                      MushafMetadata mushaf,
                    ) {
                      final isSelected =
                          provider.currentMushafId == mushaf.identifier;
                      final isDownloaded =
                          mushaf.isDownloaded || mushaf.type == 'digital';
                      final isDownloading =
                          provider.isDownloading &&
                          provider.currentDownloadingId == mushaf.identifier;

                      String sizeEstimate = '';
                      if (mushaf.identifier == 'qcf2_v4_woff2') {
                        sizeEstimate = '58 MB';
                      }
                      if (mushaf.identifier == 'madani_old_v1') {
                        sizeEstimate = '50 MB';
                      }
                      if (mushaf.identifier == 'shamarly_15lines') {
                        sizeEstimate = '74 MB';
                      }

                      // حالة العنصر حسب النوع
                      String statusText;
                      if (isDownloading) {
                        statusText =
                            '${(provider.downloadProgress * 100).toInt()}%';
                      } else if (mushaf.type == 'digital') {
                        statusText = AppLocalizations.of(context)!
                            .settingsReady;
                      } else if (mushaf.type == 'single_font') {
                        statusText = 'خط واحد مضمّن · يعمل دون اتصال';
                      } else if (isDownloaded) {
                        statusText = AppLocalizations.of(context)!
                            .settingsDownloaded;
                      } else {
                        statusText = AppLocalizations.of(context)!
                            .settingsNotDownloaded;
                      }
                      return _CompactSettingItem(
                        title: mushaf.nameArabic ?? mushaf.identifier!,
                        subtitle: statusText,
                        isSelected: isSelected,
                        isDownloaded: isDownloaded,
                        isDownloading: isDownloading,
                        progress: provider.downloadProgress,
                        sizeEstimate: sizeEstimate,
                        onActivate: () =>
                            provider.setMushaf(mushaf.identifier!),
                        onDownload: () => showDownloadFailure(context, provider.downloadMushaf(mushaf.identifier!)),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tafsir
          _CompactExpandableCard(
            title: AppLocalizations.of(context)!.settingsTafsirs,
            subtitle: _getTafsirName(context, settings.defaultTafsir),
            icon: Icons.library_books,
            color: Colors.green,
            children: [
              // 1. التفسير الميسر (محلي) - Special handling
              Consumer<LocalTafsirService>(
                builder: (context, LocalTafsirService local, _) {
                  final isSelected = settings.defaultTafsir == 'muyassar';
                  final bool isDownloaded =
                      local.isLoaded && local.totalEntries > 0;

                  String subtitle = isDownloaded
                      ? AppLocalizations.of(context)!.settingsOffline
                      : AppLocalizations.of(context)!.initWait;
                  if (local.lastError != null &&
                      !local.isDownloading &&
                      !isDownloaded) {
                    subtitle =
                        '${AppLocalizations.of(context)!.error}: ${local.lastError}';
                  }

                  return _CompactSettingItem(
                    title: AppLocalizations.of(context)!.tafsirMuyassar,
                    subtitle: subtitle,
                    isSelected: isSelected,
                    isDownloaded: isDownloaded,
                    isDownloading: local.isDownloading,
                    progress: local.downloadProgress,
                    sizeEstimate: '4 MB',
                    onActivate: () => context
                        .read<SettingsProvider>()
                        .updateDefaultTafsir('muyassar'),
                    onDownload: () =>
                        showDownloadFailure(context,local.downloadAndExtractTafsir()),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // 2. باقي التفاسير (أونلاين)
              ...[
                {'id': 'tafsir-katheer', 'name': 'تفسير ابن كثير'},
                {'id': 'tafsir-saadi', 'name': 'تفسير السعدي'},
                {'id': 'tafsir-baghawy', 'name': 'تفسير البغوي'},
                {'id': 'tafsir-tabary', 'name': 'تفسير الطبري'},
                {'id': 'eerab-aya', 'name': 'إعراب القرآن'},
              ].map((tafsir) {
                final isSelected = settings.defaultTafsir == tafsir['id'];
                return _CompactSettingItem(
                  title: tafsir['name']!,
                  subtitle: AppLocalizations.of(context)!.settingsOnline,
                  isSelected: isSelected,
                  isDownloaded: false, // Online tafsirs are NOT downloaded
                  isOnline: true, // Mark as online
                  onActivate: () => context
                      .read<SettingsProvider>()
                      .updateDefaultTafsir(tafsir['id']!),
                  onDownload: () {},
                );
              }),
            ],
          ),

          const SizedBox(height: 8),

          // Audio
          _CompactExpandableCard(
            title: AppLocalizations.of(context)!.settingsReader,
            subtitle: context
                .read<AudioProvider>()
                .reciters
                .firstWhere(
                  (r) => r.id == settings.defaultReciter,
                  orElse: () => Reciter(
                    id: '',
                    name: 'اختر القارئ',
                    style: '',
                    bitrate: '',
                  ),
                )
                .name,
            icon: Icons.record_voice_over,
            color: Colors.purple,
            children: [
              Consumer<AudioProvider>(
                builder: (context, audio, _) {
                  return Column(
                    children: audio.reciters.map((reciter) {
                      final isSelected = settings.defaultReciter == reciter.id;
                      return _CompactSettingItem(
                        title: reciter.name,
                        subtitle: AppLocalizations.of(context)!
                            .settingsStreaming,
                        isSelected: isSelected,
                        isDownloaded: false,
                        isOnline: true,
                        onActivate: () {
                          context.read<SettingsProvider>().updateDefaultReciter(
                            reciter.id,
                          );
                          context.read<AudioProvider>().setReciter(reciter);
                        },
                        onDownload: () {},
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          const Divider(height: 24),

          // 3. Footer (Very Compact)
          Center(
            child: Text(
              '${AppLocalizations.of(context)!.appName} v$_version',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDownloadCenterLink(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/download_center'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandGold,
              AppColors.brandGold.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGold.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: Colors.white, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مركز التحميل',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'إدارة المصاحف والتفاسير المحملة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticLink(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecitationDiagnosticScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('🔬', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تشخيص نظام التسميع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'إذن الميكروفون وملفات Zipformer وتهيئة NPU',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecitationSettingsLink(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _RecitationSetupPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A1A) : const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.brandGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Consumer<RecitationProvider>(
                builder: (context, recProvider, _) {
                  final status = recProvider.recitationAvailabilityLabel;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إعدادات ومحرك التسميع',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: recProvider.isZipformerDownloaded &&
                                  recProvider.engine ==
                                      RecitationEngine.zipformer &&
                                  recProvider.isNpuSupported
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _getTafsirName(BuildContext context, String id) {
    final localizations = AppLocalizations.of(context)!;
    switch (id) {
      case 'muyassar':
        return localizations.tafsirMuyassar;
      case 'tafsir-katheer':
        return 'تفسير ابن كثير';
      case 'tafsir-saadi':
        return 'تفسير السعدي';
      case 'tafsir-baghawy':
        return 'تفسير البغوي';
      case 'tafsir-tabary':
        return 'تفسير الطبري';
      case 'eerab-aya':
        return 'إعراب القرآن';
      default:
        return id;
    }
  }

  Widget _buildInlineSettingRow(
    BuildContext context,
    String title,
    Widget controlWidget,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 70, // Fixed width for consistent alignment
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: controlWidget),
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

/// صفحة إعدادات التسميع الكاملة (تفتح من الإعدادات)
class _RecitationSetupPage extends StatelessWidget {
  const _RecitationSetupPage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecitationProvider>();
    final hasActiveSession = provider.activeSessionConfig != null;
    return PopScope<Object?>(
      canPop: !hasActiveSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !hasActiveSession) return;
        final route = ModalRoute.of(context);
        await provider.cancelRecording();
        if (context.mounted && route?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إعدادات التسميع',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const RecitationScreen(),
      ),
    );
  }
}

class _CompactThemeButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactThemeButton({
    required this.title,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 12
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 2)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.grey,
                size: 16,
              ), // Reduced size
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
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

  const _CompactExpandableCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
  });

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
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18), // Reduced
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _CompactSettingItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isOnline;
  final double? progress;
  final String? sizeEstimate;
  final VoidCallback onActivate;
  final VoidCallback onDownload;

  const _CompactSettingItem({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.isDownloaded,
    this.isDownloading = false,
    this.isOnline = false,
    this.progress,
    this.sizeEstimate,
    required this.onActivate,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withAlpha(12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9,
                      color: isSelected
                          ? AppColors.primary.withAlpha(178)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator if downloading
              if (isDownloading)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${((progress ?? 0) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              // Online indicator (streaming/internet required)
              else if (isOnline && !isDownloaded)
                const Icon(Icons.language, size: 16, color: Colors.blue)
              // Download Button and size estimate if not downloaded
              else if (!isDownloaded)
                Row(
                  children: [
                    if (sizeEstimate != null && sizeEstimate!.isNotEmpty)
                      Text(
                        sizeEstimate!,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onDownload,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),

              const SizedBox(width: 8),

              // Activate Button
              InkWell(
                onTap: onActivate,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSelected
                        ? AppLocalizations.of(context)!.active
                        : AppLocalizations.of(context)!.activate,
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
