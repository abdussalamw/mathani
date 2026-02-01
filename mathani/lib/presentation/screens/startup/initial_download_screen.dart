import 'package:flutter/material.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/data/services/qcf4_font_downloader.dart';
import 'package:mathani/presentation/screens/home/main_shell_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class InitialDownloadScreen extends StatefulWidget {
  const InitialDownloadScreen({Key? key}) : super(key: key);

  @override
  State<InitialDownloadScreen> createState() => _InitialDownloadScreenState();
}

class _InitialDownloadScreenState extends State<InitialDownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'يتطلب التطبيق تحميل ملفات الخطوط\n(حجم التحميل: حوالي 55 ميجابايت)';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkFonts();
  }

  Future<void> _checkFonts() async {
    final available = await QCF4FontDownloader.areAllFontsAvailable();
    if (available) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _statusMessage = 'جاري الاتصال بالخادم...';
      _progress = 0.0;
    });
    
    // Keep screen on
    await WakelockPlus.enable();

    try {
      await QCF4FontDownloader.downloadAllFonts(
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
            });
          }
        },
        onStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
            });
          }
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
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _statusMessage = 'حدث خطأ أثناء التحميل.\nتأكد من اتصالك بالإنترنت وحاول مرة أخرى.\n($e)';
        });
      }
    } finally {
      // Disable wakelock
      await WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            const Icon(
              Icons.cloud_download_outlined,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'تحميل ملفات المصحف',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Text
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
            const SizedBox(height: 48),
            
            // Action
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'تحميل الآن',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            
            if (_hasError) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   // Option to skip? Maybe not if fonts are critical.
                   // For now, retry only.
                },
                child: const Text(''), 
              )
            ]
          ],
        ),
      ),
    );
  }
}
