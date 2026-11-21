import '../../widgets/download_feedback.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../../data/services/local_tafsir_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/recitation_provider.dart';

class DownloadCenterScreen extends StatefulWidget {
  const DownloadCenterScreen({super.key});

  @override
  State<DownloadCenterScreen> createState() => _DownloadCenterScreenState();
}

class _DownloadCenterScreenState extends State<DownloadCenterScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131315)
          : AppColors.brandBackground,
      appBar: AppBar(
        title: Text(
          l10n.indexTab, // Use a generic title or "مركز التحميل"
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: AppColors.slateText,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.slateText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(context, isDark),
          _buildSearchBar(context, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildCategoryHeader(context, l10n.settingsMushafs),
                _buildMushafList(context),
                const SizedBox(height: 24),
                _buildCategoryHeader(context, l10n.settingsTafsirs),
                _buildTafsirList(context),
                const SizedBox(height: 24),
                _buildCategoryHeader(
                  context,
                  'نماذج الذكاء الاصطناعي (التسميع)',
                ),
                _buildAiModelsList(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCFB058), Color(0xFFB09040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCFB058).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_download_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز التحميل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'إدارة المصاحف والتفاسير المحملة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '120 MB',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: 'البحث عن مصحف أو تفسير...',
          hintStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: AppColors.mutedText,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.brandGold),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.brandGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafList(BuildContext context) {
    return Consumer<MushafMetadataProvider>(
      builder: (context, provider, _) {
        return Column(
          children: provider.availableMushafs
              .where((m) => m.nameArabic?.contains(searchQuery) ?? true)
              .map(
                (m) => _buildDownloadCard(
                  context,
                  title: m.nameArabic ?? m.identifier!,
                  subtitle: m.type == 'single_font'
                      ? 'خط واحد مضمّن · يعمل دون اتصال'
                      : m.type == 'digital'
                      ? 'مصحف رقمي'
                      : 'مصحف مصور',
                  isDownloaded: m.isDownloaded || m.type == 'digital',
                  isDownloading:
                      provider.isDownloading &&
                      provider.currentDownloadingId == m.identifier,
                  progress:
                      provider.isDownloading &&
                          provider.currentDownloadingId == m.identifier
                      ? provider.downloadProgress
                      : 0,
                  size: m.type == 'single_font'
                      ? 'مضمّن'
                      : m.identifier == 'shamarly_15lines'
                      ? '74 MB'
                      : '50 MB',
                  onDownload: () => showDownloadFailure(context, provider.downloadMushaf(m.identifier!)),
                  onActivate: () => provider.setMushaf(m.identifier!),
                  isSelected: provider.currentMushafId == m.identifier,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTafsirList(BuildContext context) {
    return Consumer<LocalTafsirService>(
      builder: (context, local, _) {
        final settings = context.read<SettingsProvider>();
        return Column(
          children: [
            _buildDownloadCard(
              context,
              title: 'التفسير الميسر',
              subtitle: 'تفسير مختصر وشامل للآيات',
              isDownloaded: local.isLoaded && local.totalEntries > 0,
              isDownloading: local.isDownloading,
              progress: local.downloadProgress,
              size: '4 MB',
              onDownload: () => showDownloadFailure(context,local.downloadAndExtractTafsir()),
              onActivate: () => settings.updateDefaultTafsir('muyassar'),
              isSelected: settings.defaultTafsir == 'muyassar',
            ),
            // Other tafsirs could be added here as "Online" cards
          ],
        );
      },
    );
  }

  Widget _buildAiModelsList(BuildContext context) {
    return Consumer<RecitationProvider>(
      builder: (context, provider, _) {
        final npuStatus = switch ((
          provider.isNpuSupported,
          provider.isZipformerDownloading,
          provider.isZipformerDownloaded,
        )) {
          (false, _, _) =>
            provider.npuUnavailableReason ?? 'مسار NPU غير متاح للجهاز حاليًا.',
          (true, true, _) => provider.zipformerStatusText,
          (true, false, false) => provider.zipformerStatusText.isEmpty
              ? 'حزمة Hexagon ومرجع الفونيمات للتنزيل.'
              : provider.zipformerStatusText,
          (true, false, true) => 'الملفات موجودة. يُختبر NPU عند بدء التسميع.',
        };
        return Column(
          children: [
            _buildDownloadCard(
              context,
              title: 'محرك التسميع الذكي (Zipformer V3)',
              subtitle: npuStatus,
              isDownloaded: provider.isZipformerDownloaded,
              isDownloading: provider.isZipformerDownloading,
              progress: provider.zipformerDownloadProgress,
              size: '164 MB',
              badge: 'المعتمد',
              badgeColor: Colors.green,
              onDownload: provider.isNpuSupported
                  ? provider.downloadZipformerModel
                  : null,
              onActivate: provider.isNpuSupported
                  ? () => provider.setRecitationEngine(RecitationEngine.zipformer)
                  : null,
              onDelete: provider.isZipformerDownloaded &&
                      provider.activeSessionConfig == null
                  ? () => _confirmDeleteModel(
                        context,
                        'محرك Zipformer V3',
                        provider.deleteZipformerModel,
                      )
                  : null,
              isSelected: provider.engine == RecitationEngine.zipformer,
            ),
            _buildDownloadCard(
              context,
              title: 'محرك التسميع الكلاسيكي (Whisper)',
              subtitle:
                  'قيد التطوير إلى حين إصلاح تحويل النموذج.',
              isDownloaded: provider.isWhisperDownloaded,
              isDownloading: false,
              progress: 0,
              size: '142 MB',
              badge: 'قيد التطوير',
              badgeColor: Colors.amber[800],
              isSelected: false,
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteModel(
    BuildContext context,
    String modelTitle,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف $modelTitle',
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل ترغب في حذف ملفات $modelTitle لتوفير المساحة؟ يمكنك إعادة تنزيلها لاحقاً في أي وقت.',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isDownloaded,
    required bool isDownloading,
    required double progress,
    required String size,
    VoidCallback? onDownload,
    VoidCallback? onActivate,
    required bool isSelected,
    String? badge,
    Color? badgeColor,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.brandGold, width: 1.5)
            : Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail Placeholder
          Container(
            width: 50,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.brandGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppColors.brandGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.brandGold)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (badgeColor ?? AppColors.brandGold)
                                .withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor ?? AppColors.brandGold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandGold,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                size,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
              if (onDownload != null || onActivate != null || onDelete != null)
                const SizedBox(height: 8),
              if (isDownloaded && (onActivate != null || onDelete != null))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        tooltip: 'حذف لتوفير المساحة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    if (onDelete != null) const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isSelected ? null : onActivate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.green.withValues(alpha: 0.1)
                            : AppColors.brandGold,
                        foregroundColor:
                            isSelected ? Colors.green : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isSelected ? 'مفعل' : 'تفعيل',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else if (isDownloading)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.brandGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else if (!isDownloaded && onDownload != null)
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(
                    Icons.download_for_offline_rounded,
                    color: AppColors.brandGold,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
