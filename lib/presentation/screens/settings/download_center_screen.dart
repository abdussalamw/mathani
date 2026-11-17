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
                  subtitle: m.type == 'digital' ? 'مصحف رقمي' : 'مصحف مصور',
                  isDownloaded: m.isDownloaded || m.type == 'digital',
                  isDownloading:
                      provider.isDownloading &&
                      provider.currentDownloadingId == m.identifier,
                  progress:
                      provider.isDownloading &&
                          provider.currentDownloadingId == m.identifier
                      ? provider.downloadProgress
                      : 0,
                  size: m.identifier == 'shamarly_15lines' ? '74 MB' : '50 MB',
                  onDownload: () => provider.downloadMushaf(m.identifier!),
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
              onDownload: () => local.downloadAndExtractTafsir(),
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
        return Column(
          children: [
            _buildDownloadCard(
              context,
              title: 'نموذج التعرف الصوتي (Whisper)',
              subtitle: 'لتحليل التلاوة ومطابقتها مع النص القرآني',
              isDownloaded: provider.isAsrModelDownloaded,
              isDownloading: provider.isAsrDownloading,
              progress: provider.asrDownloadProgress,
              size: '142 MB',
              onDownload: () => provider.downloadAsrModel(),
              onActivate: () {},
              isSelected: provider.isAsrModelDownloaded,
            ),
            // ملاحظة: بطاقة "مصنف التجويد" أزيلت — لا يوجد نموذج حقيقي بعد،
            // والنتائج السابقة كانت محاكاة زائفة (لا نعرض ميزات وهمية للمستخدم).
          ],
        );
      },
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
    required VoidCallback onDownload,
    required VoidCallback onActivate,
    required bool isSelected,
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
              Icons.menu_book_rounded,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateText,
                  ),
                ),
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
                      value: progress,
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
              const SizedBox(height: 8),
              if (isDownloaded)
                ElevatedButton(
                  onPressed: isSelected ? null : onActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Colors.green.withValues(alpha: 0.1)
                        : AppColors.brandGold,
                    foregroundColor: isSelected ? Colors.green : Colors.white,
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
              else
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
