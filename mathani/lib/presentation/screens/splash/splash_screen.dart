import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/qcf4_font_downloader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Check if fonts are available
    final fontsReady = await QCF4FontDownloader.areAllFontsAvailable();
    
    if (mounted) {
      if (fontsReady) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'اللَّهُ نَزَّلَ أَحْسَنَ الْحَدِيثِ كِتَابًا مُّتَشَابِهًا مَّثَانِيَ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
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
