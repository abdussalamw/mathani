import 'dart:async';

import '../../../l10n/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/local_tafsir_service.dart';
import '../../providers/mushaf_metadata_provider.dart';

import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _navigateToHome();
  }

  bool _startupFailed = false;

  Future<void> _navigateToHome({bool retry = false}) async {
    try {
      final provider = context.read<MushafMetadataProvider>();
      if (retry) {
        setState(() => _startupFailed = false);
        await provider.refresh();
      } else {
        await Future.wait([
          Future<void>.delayed(const Duration(seconds: 2)),
          if (!provider.isInitialized) provider.initialized,
        ]);
      }

      if (!mounted) return;
      final error = provider.initializationError;
      if (error != null) throw error;

      final currentId = provider.currentMushafId;

      // 4. Check if selected Mushaf is ready
      final mushafReady = provider.availableMushafs.any(
        (m) => m.identifier == currentId && m.isDownloaded,
      );

      if (mounted) {
        if (mushafReady) {
          // إذا كان المصحف جاهزاً، ندخل القراءة مباشرة دون حجب المستخدم
          unawaited(LocalTafsirService.instance.loadTafsirData());
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/initial_download');
        }
      }
    } catch (e) {
      debugPrint('Startup navigation error: $e');
      if (mounted) setState(() => _startupFailed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الأيقونة
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden30,
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/icon.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // الآية القرآنية
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'اللَّهُ نَزَّلَ أَحْسَنَ الْحَدِيثِ كِتَابًا مُّتَشَابِهًا مَّثَانِيَ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                      height: 1.8,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // مؤشر التحميل
                if (_startupFailed) ...[
                  Text(AppLocalizations.of(context)!.errorLoading),
                  TextButton(
                    onPressed: () => _navigateToHome(retry: true),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ] else
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
