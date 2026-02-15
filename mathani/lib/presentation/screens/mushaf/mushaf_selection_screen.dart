
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/collections.dart'; // Import required for MushafMetadata model
import '../../providers/mushaf_metadata_provider.dart';

class MushafSelectionScreen extends StatefulWidget {
  const MushafSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MushafSelectionScreen> createState() => _MushafSelectionScreenState();
}

class _MushafSelectionScreenState extends State<MushafSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // محاولة تحديث البيانات عند فتح الصفحة إذا كانت القائمة فارغة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MushafMetadataProvider>();
      if (provider.availableMushafs.isEmpty) {
        provider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'مكتبة المصاحف',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<MushafMetadataProvider>(
        builder: (context, MushafMetadataProvider provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.availableMushafs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لم يتم تحميل قائمة المصاحف بعد'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة محاولة التحميل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.availableMushafs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final mushaf = provider.availableMushafs[index];
              final isSelected = mushaf.identifier == provider.currentMushafId;
              final isDownloadingThis = provider.isDownloading && provider.currentDownloadingId == mushaf.identifier;
              // تحقق خاص لـ qcf2 - إذا لم يكن محملاً يحتاج تحميل
              final isQcf2 = mushaf.identifier == 'qcf2_v4_woff2';
              final isImage = (mushaf.type ?? '') == 'image';
              
              // If it's Shamarly (ZIP based), we want to encourage download but also allow usage (on-demand fallback?)
              // For now, if URL is zip, we require download or at least show the button
              final isZip = mushaf.baseUrl?.endsWith('.zip') ?? false;
              
              // Needs download if:
              // 1. Not isDownloaded AND (isZip OR isQcf2)
              // 2. Note: We relaxed isImage check before, now we tighten it for ZIPs
              final needsDownload = !mushaf.isDownloaded && (isZip || isQcf2);
              
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey10,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black05,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary10 : AppColors.grey10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : ((mushaf.type ?? '').contains('font') ? Icons.text_fields : Icons.menu_book_rounded),
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        mushaf.nameArabic ?? 'مصحف',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          (mushaf.type ?? '').contains('font') 
                              ? (mushaf.identifier != null && mushaf.identifier!.contains('qcf') ? 'خطوط الرسم العثماني (QCF2) الماركة' : 'نسخة رقمية خفيفة وسريعة')
                              : 'نسخة الصور (تحتاج إنترنت للتحميل)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (isDownloadingThis)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: provider.downloadProgress),
                            const SizedBox(height: 8),
                            Text('جاري التحميل ${(provider.downloadProgress * 100).toInt()}%'),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey05,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            const Text(
                              'مستخدم حالياً ✅',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          else if (needsDownload && !isDownloadingThis)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('تنزيل المصحف'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                if (mushaf.identifier != null) {
                                  provider.downloadMushaf(mushaf.identifier!);
                                }
                              },
                            )
                          else if (!needsDownload)
                            OutlinedButton(
                              child: const Text('تفعيل هذه النسخة'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                if (mushaf.identifier != null) {
                                  provider.setMushaf(mushaf.identifier!);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
