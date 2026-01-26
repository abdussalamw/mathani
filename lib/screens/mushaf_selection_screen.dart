
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/mushaf_metadata_provider.dart';

class MushafSelectionScreen extends StatelessWidget {
  const MushafSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'مكتبة المصاحف',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Consumer<MushafMetadataProvider>(
        builder: (context, provider, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.availableMushafs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final mushaf = provider.availableMushafs[index];
              final isSelected = mushaf.identifier == provider.currentMushafId;
              final isDownloadingThis = provider.isDownloading && provider.currentDownloadingId == mushaf.identifier;
              final needsDownload = !mushaf.isDownloaded && mushaf.baseUrl != null;
              
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.menu_book_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        mushaf.nameArabic,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          mushaf.type.contains('font') 
                              ? 'نسخة رقمية خفيفة وسريعة (تعمل دائماً)' 
                              : 'نسخة مطابقة لمصحف المدينة (QCF2) بجودة عالية',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    // شريط الإجراءات السفلي
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            const Text(
                              'مستخدم حالياً',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          else if (isDownloadingThis)
                             Expanded(
                               child: Row(
                                 children: [
                                   SizedBox(
                                     height: 20, 
                                     width: 20, 
                                     child: CircularProgressIndicator(strokeWidth: 2, value: provider.downloadProgress)
                                   ),
                                   const SizedBox(width: 12),
                                   Text(
                                     'جاري التحميل ${(provider.downloadProgress * 100).toInt()}%',
                                     style: const TextStyle(fontSize: 12, color: Colors.grey),
                                   ),
                                 ],
                               ),
                             )
                          else if (needsDownload)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('تحميل (55MB)'), // حجم تقريبي للوضوح
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => provider.downloadMushaf(mushaf.identifier),
                            )
                          else
                            OutlinedButton(
                              child: const Text('تفعيل'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                provider.setMushaf(mushaf.identifier);
                                Navigator.pop(context); // الرجوع للإعدادات
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
