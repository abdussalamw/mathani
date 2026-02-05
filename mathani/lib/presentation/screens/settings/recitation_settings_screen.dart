import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/quran_provider.dart';
import '../../../core/services/audio_service.dart';

class RecitationSettingsScreen extends StatefulWidget {
  const RecitationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<RecitationSettingsScreen> createState() => _RecitationSettingsScreenState();
}

class _RecitationSettingsScreenState extends State<RecitationSettingsScreen> {
  final AudioService _audioService = AudioService();
  Map<String, Map<String, dynamic>> _stats = {};
  bool _isLoadingStats = true;
  String? _downloadingReciterId;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final audio = context.read<AudioProvider>();
    final newStats = <String, Map<String, dynamic>>{};

    for (var reciter in audio.reciters) {
      final id = reciter['id']!;
      final stats = await _audioService.getReciterStats(id);
      final size = await _audioService.getReciterStorageUsage(id);
      newStats[id] = {
        'ayahs': stats['ayahs'],
        'size': size,
      };
    }
    
    if (mounted) {
      setState(() {
        _stats = newStats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _downloadFullMushaf(String reciterId) async {
    // Check if already downloading
    if (_downloadingReciterId != null) return;

    final quran = context.read<QuranProvider>();
    // Ensure surahs are loaded (though they usually are by app start)
    // We assume quran.surahs is populated. If not, we might need to wait or load.
    // However, QuranProvider usually loads JSON on init.
    
    // Safety check
    if (quran.surahs.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('يرجى الانتظار حتى يتم تحميل بيانات المصحف...')),
       );
       return;
    }

    setState(() {
      _downloadingReciterId = reciterId;
      _downloadProgress = 0.0;
    });

    int total = 6236; // Approx
    int current = 0;
    
    // Helper to process download
    // We will loop through all surahs and ayahs
    try {
      for (var surah in quran.surahs) {
        for (int ayah = 1; ayah <= surah.numberOfAyahs; ayah++) {
           if (!mounted) break;
           
           // Check if we need to stop/cancel? (Not implemented yet, simply break if left screen)
           if (_downloadingReciterId != reciterId) break; 

           await _audioService.downloadAyah(reciterId, surah.number, ayah);
           
           current++;
           if (current % 10 == 0) { // Update UI every 10 ayahs to reduce overhead
             setState(() {
               _downloadProgress = current / total;
             });
           }
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingReciterId = null;
          _downloadProgress = 0.0;
        });
        _loadStats(); // Refresh stats
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'إعدادات التلاوة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Global Settings
          _buildSection(
            context,
            title: 'خيارات التحميل',
            children: [
               Consumer<SettingsProvider>(
                 builder: (context, settings, _) => SwitchListTile(
                   title: const Text('تحميل التلاوة أثناء الاستماع', style: TextStyle(fontFamily: 'Tajawal')),
                   subtitle: const Text('يقوم بحفظ الآيات تلقائياً للعمل دون إنترنت', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                   value: settings.downloadWhilePlaying,
                   onChanged: (val) => settings.toggleDownloadWhilePlaying(),
                   activeTrackColor: AppColors.primary,
                 ),
               ),
            ],
          ),
          
          const SizedBox(height: 24),

          _buildSection(
            context,
            title: 'إدارة القراء',
            children: [
              Consumer<AudioProvider>(
                builder: (context, audio, _) {
                  return Column(
                    children: audio.reciters.map((reciter) {
                      final id = reciter['id']!;
                      final name = reciter['name']!;
                      
                      final stats = _stats[id] ?? {'ayahs': 0, 'size': 0.0};
                      final ayahsCount = stats['ayahs'] as int;
                      final sizeMb = stats['size'] as double;
                      final isDefault = context.watch<SettingsProvider>().defaultReciter == id;
                      
                      final isDownloading = _downloadingReciterId == id;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                                      color: isDefault ? AppColors.primary : null,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('الافتراضي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppColors.primary)),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _isLoadingStats 
                                    ? 'جاري حساب المساحة...' 
                                    : 'تم تحميل: $ayahsCount آية (${sizeMb.toStringAsFixed(1)} ميجابايت)',
                                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey[600]),
                                ),
                                if (isDownloading) ...[
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: _downloadProgress, backgroundColor: Colors.grey[200], color: AppColors.primary),
                                  Text(
                                    'جاري التحميل... ${( _downloadProgress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal'),
                                  ),
                                ]
                              ],
                            ),
                            trailing: isDownloading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'set_default') {
                                        context.read<SettingsProvider>().updateDefaultReciter(id);
                                        // Update AudioProvider current reciter too if needed or keep separate
                                        context.read<AudioProvider>().setReciter(reciter);
                                      } else if (val == 'download') {
                                        _showDownloadDialog(context, reciter);
                                      } else if (val == 'delete') {
                                        _showDeleteDialog(context, reciter);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'set_default',
                                        child: Text('تعيين كافتراضي', style: TextStyle(fontFamily: 'Tajawal')),
                                      ),
                                      const PopupMenuItem(
                                        value: 'download',
                                        child: Text('تحميل المصحف كاملاً', style: TextStyle(fontFamily: 'Tajawal')),
                                      ),
                                      if (ayahsCount > 0)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('حذف الملفات المؤقتة', style: TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
                                        ),
                                    ],
                                  ),
                            onTap: () {
                              context.read<SettingsProvider>().updateDefaultReciter(id);
                              context.read<AudioProvider>().setReciter(reciter);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, Map<String, String> reciter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحميل المصحف كاملاً', style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text(
          'سيتم تحميل جميع سور المصحف لهذا القارئ.\nحجم التحميل المتوقع قد يتجاوز 600 ميجابايت.\nهل تريد المتابعة؟',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFullMushaf(reciter['id']!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('بدء التحميل', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, String> reciter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الملفات', style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text(
          'هل أنت متأكد من حذف جميع التلاوات المحملة لهذا القارئ؟',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _audioService.deleteReciterData(reciter['id']!);
              _loadStats();
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF2C2416) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 1,
          child: Column(children: children),
        ),
      ],
    );
  }
}
