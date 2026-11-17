import 'dart:io';

void main() {
  final file = File(
    'c:/Projects/New app/mathani/lib/presentation/screens/settings/settings_screen.dart',
  );
  var content = file.readAsStringSync();

  // 1. Fix the `isDownloaded` assignment
  content = content.replaceFirst(
    "final isDownloaded = mushaf.isDownloaded || mushaf.type == 'font_v2' || mushaf.type == 'digital';",
    "final isDownloaded = mushaf.isDownloaded || mushaf.type == 'digital';",
  );

  // 2. Add size estimate to the item creation
  content = content.replaceFirst(
    '''
                      return _CompactSettingItem(
                        title: mushaf.nameArabic ?? '',
                        isSelected: isSelected,
                        isDownloaded: isDownloaded,
                        onActivate: () => provider.setMushaf(mushaf.identifier!),
                        onDownload: () => provider.downloadMushaf(mushaf.identifier!),
                      );''',
    '''
                      final isDownloading = provider.isDownloading && provider.currentDownloadingId == mushaf.identifier;
                      String sizeEstimate = '';
                      if (mushaf.identifier == 'qcf2_v4_woff2') sizeEstimate = '58 ميجابايت';
                      if (mushaf.identifier == 'madani_old_v1') sizeEstimate = '50 ميجابايت';
                      if (mushaf.identifier == 'shamarly_15lines') sizeEstimate = '74 ميجابايت';

                      return _CompactSettingItem(
                        title: mushaf.nameArabic ?? '',
                        isSelected: isSelected,
                        isDownloaded: isDownloaded,
                        isDownloading: isDownloading,
                        progress: provider.downloadProgress,
                        sizeEstimate: sizeEstimate,
                        onActivate: () => provider.setMushaf(mushaf.identifier!),
                        onDownload: () => provider.downloadMushaf(mushaf.identifier!),
                      );''',
  );

  // 3. Update the _CompactSettingItem constructor & fields
  content = content.replaceFirst(
    '''
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
  });''',
    '''
class _CompactSettingItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDownloaded;
  final bool isDownloading;
  final double? progress;
  final String? sizeEstimate;
  final VoidCallback onActivate;
  final VoidCallback onDownload;

  const _CompactSettingItem({
    required this.title,
    required this.isSelected,
    this.isDownloading = false,
    this.progress,
    this.sizeEstimate,
    required this.onActivate,
    required this.onDownload,
  });''',
  );

  // 4. Update the _CompactSettingItem build method to show progress/size
  content = content.replaceFirst(
    '''
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
''',
    '''
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDownloading)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\${((progress ?? 0) * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else if (!isDownloaded)
                Row(
                  children: [
                    if (sizeEstimate != null && sizeEstimate!.isNotEmpty)
                      Text(
                        sizeEstimate!,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600], fontFamily: 'Tajawal'),
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
                        child: const Icon(Icons.download_rounded, size: 16, color: Colors.black54),
                      ),
                    ),
                  ],
                )
              else 
                 const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
''',
  );

  file.writeAsStringSync(content);
  stdout.writeln('Settings Screen patched successfully!');
}
