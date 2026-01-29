import 'package:flutter/material.dart';
import 'package:mathani_quran/core/services/fonts_downloader_service.dart';
import 'package:mathani_quran/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FontsDownloadScreen extends StatefulWidget {
  const FontsDownloadScreen({Key? key}) : super(key: key);

  @override
  State<FontsDownloadScreen> createState() => _FontsDownloadScreenState();
}

class _FontsDownloadScreenState extends State<FontsDownloadScreen> {
  double _downloadProgress = 0.0;
  String _statusMessage = 'جاهز للتحميل';
  bool _isDownloading = false;
  bool _downloadComplete = false;
  bool _downloadFailed = false;
  
  @override
  void initState() {
    super.initState();
    _checkFonts();
  }
  
  Future<void> _checkFonts() async {
    final fontsService = FontsDownloaderService.instance;
    final areDownloaded = await fontsService.areFontsDownloaded();
    
    if (areDownloaded && mounted) {
      // الخطوط موجودة مسبقاً، انتقل للصفحة الرئيسية
      _navigateToHome();
    }
  }
  
  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadFailed = false;
      _downloadProgress = 0.0;
    });
    
    final fontsService = FontsDownloaderService.instance;
    
    final success = await fontsService.downloadFonts(
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
      onStatusUpdate: (message) {
        setState(() {
          _statusMessage = message;
        });
      },
    );
    
    setState(() {
      _isDownloading = false;
      _downloadComplete = success;
      _downloadFailed = !success;
    });
    
    if (success) {
      // انتظر ثانيتين ثم انتقل
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToHome();
      }
    }
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.golden.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _downloadComplete
                        ? Icons.check_circle
                        : _downloadFailed
                            ? Icons.error
                            : Icons.font_download,
                    size: 64,
                    color: _downloadComplete
                        ? Colors.green
                        : _downloadFailed
                            ? Colors.red
                            : AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // العنوان
              Text(
                'تحميل الخطوط القرآنية',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // الوصف
              Text(
                'للحصول على أفضل تجربة في قراءة المصحف،\nيجب تحميل خطوط الرسم العثماني',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  color: AppColors.darkBrown.withOpacity(0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // الحجم المتوقع
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'الحجم: ~50 ميجابايت',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // شريط التقدم
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _downloadProgress / 100,
                  backgroundColor: AppColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '${_downloadProgress.toStringAsFixed(0)}%',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // رسالة الحالة
              Text(
                _statusMessage,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.darkBrown.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // زر التحميل
              if (!_isDownloading && !_downloadComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _downloadFailed ? _startDownload : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_downloadFailed ? Icons.refresh : Icons.download),
                        const SizedBox(width: 8),
                        Text(
                          _downloadFailed ? 'إعادة المحاولة' : 'تحميل الخطوط',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // زر التخطي (اختياري)
              if (!_isDownloading && !_downloadComplete)
                TextButton(
                  onPressed: () {
                    // يمكن السماح للمستخدم بالتخطي واستخدام خط احتياطي
                    _navigateToHome();
                  },
                  child: Text(
                    'استخدام الخط الاحتياطي',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: AppColors.greyDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
