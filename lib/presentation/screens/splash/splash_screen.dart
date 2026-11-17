import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/qcf4_font_downloader.dart';
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

  void _navigateToHome() async {
    // 1. Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final provider = context.read<MushafMetadataProvider>();

    // 2. Wait for Provider to initialize (max 5 seconds timeout)
    int retryCount = 0;
    while (!provider.isInitialized && retryCount < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }

    if (!mounted) return;

    final currentId = provider.currentMushafId;

    // 3. Check if Tafseer is ready
    final tafsirReady = await LocalTafsirService.instance.isTafsirDownloaded();

    // 4. Check if selected Mushaf is ready
    bool mushafReady = false;
    if (currentId == 'qcf2_v4_woff2') {
      mushafReady = await QCF4FontDownloader.areAllFontsAvailable();
    } else {
      final mushafList = provider.availableMushafs;
      if (mushafList.isNotEmpty) {
        final mushaf = mushafList.firstWhere(
          (m) => m.identifier == currentId,
          orElse: () => mushafList.first,
        );
        mushafReady = mushaf.isDownloaded;
      }
    }

    if (mounted) {
      if (tafsirReady && mushafReady) {
        // Load tafsir locally (background)
        LocalTafsirService.instance.loadTafsirData();
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/initial_download');
      }
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
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
