import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/qcf4_font_downloader.dart';
import '../../../../data/services/local_tafsir_service.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../home/main_shell_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class InitialDownloadScreen extends StatefulWidget {
  const InitialDownloadScreen({Key? key}) : super(key: key);

  @override
  State<InitialDownloadScreen> createState() => _InitialDownloadScreenState();
}

class _InitialDownloadScreenState extends State<InitialDownloadScreen> {
  String? _selectedMushafId;
  bool _isDownloading = false;
  double _mushafProgress = 0.0;
  double _tafsirProgress = 0.0;
  String _statusMessage = 'اختر نوع المصحف المفضل لديك للبدء...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MushafMetadataProvider>();
      if (provider.availableMushafs.isNotEmpty) {
        setState(() {
          _selectedMushafId = provider.availableMushafs.firstWhere((m) => m.identifier == 'qcf2_v4_woff2', orElse: () => provider.availableMushafs.first).identifier;
        });
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  Future<void> _startDownload() async {
    if (_selectedMushafId == null) return;
    
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _statusMessage = 'جاري تهيئة الإعدادات...';
      _mushafProgress = 0.0;
      _tafsirProgress = 0.0;
    });
    
    await WakelockPlus.enable();

    try {
      final provider = context.read<MushafMetadataProvider>();
      
      // 1. تعيين المصحف الافتراضي
      await provider.setMushaf(_selectedMushafId!);

      // 2. تحميل المصحف المختار
      setState(() {
        _statusMessage = 'جاري تحميل بيانات المصحف...';
      });

      if (_selectedMushafId == 'qcf2_v4_woff2') {
        await QCF4FontDownloader.downloadAllFonts(
          onProgress: (p) {
            if (mounted) setState(() => _mushafProgress = p);
          },
          onStatusChanged: (status) {
            if (mounted) setState(() => _statusMessage = status);
          },
        );
      } else {
        // نستمع لمؤشر تقدم تحميل المصحف من المزود
        provider.addListener(_onProviderChange);
        await provider.downloadMushaf(_selectedMushafId!);
        provider.removeListener(_onProviderChange);
        if (mounted) setState(() => _mushafProgress = 1.0);
      }

      // 3. تحميل التفسير الميسر
      setState(() {
        _statusMessage = 'جاري تحميل التفسير الميسر للقرآن الكريم...';
      });

      await LocalTafsirService.instance.downloadAndExtractTafsir(
        onProgress: (p) {
          if (mounted) setState(() => _tafsirProgress = p);
        },
      );

      // Success
      if (mounted) {
        setState(() {
          _statusMessage = 'تم التحميل بنجاح! جاري تهيئة التطبيق...';
        });
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Initial Download Error: $e');
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _statusMessage = 'حدث خطأ أثناء التحميل.\nتأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
        });
      }
    } finally {
      await WakelockPlus.disable();
    }
  }

  void _onProviderChange() {
    final provider = context.read<MushafMetadataProvider>();
    if (mounted && provider.isDownloading) {
      setState(() {
         _mushafProgress = provider.downloadProgress;
      });
    }
  }

  String _getSizeEstimate(String? identifier) {
    if (identifier == 'qcf2_v4_woff2') return '52 ميجابايت';
    if (identifier == 'madani_old_v1') return '45 ميجابايت';
    if (identifier == 'shamarly_15lines') return '70 ميجابايت';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Consumer<MushafMetadataProvider>(
            builder: (context, provider, child) {
              if (provider.availableMushafs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'تهيئة التطبيق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: _hasError ? Colors.red : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (!_isDownloading) ...[
                    Expanded(
                      child: ListView.separated(
                        itemCount: provider.availableMushafs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final mushaf = provider.availableMushafs[index];
                          final isSelected = _selectedMushafId == mushaf.identifier;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMushafId = mushaf.identifier;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String?>(
                                    value: mushaf.identifier,
                                    groupValue: _selectedMushafId,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedMushafId = val;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mushaf.nameArabic ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'حجم التنزيل: حوالي ${_getSizeEstimate(mushaf.identifier)}',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '+ التفسير الميسر للقرآن الكريم (حوالي 8 ميجابايت)',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _startDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'بدء التحميل الآن',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Downloading State UI
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'المصحف الشريف',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _mushafProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 8),
                          Text('${(_mushafProgress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          
                          const SizedBox(height: 32),
                          const Text(
                            'التفسير الميسر للقرآن الكريم',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _tafsirProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 8),
                          Text('${(_tafsirProgress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[600])),
                        ],
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        onPressed: _startDownload,
                        label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Tajawal')), 
                      )
                    ]
                  ],
                  const SizedBox(height: 16),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}
