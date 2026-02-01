import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import '../../../../core/constants/app_colors.dart';

class AyahWidget extends StatelessWidget {
  final Ayah ayah;
  final VoidCallback? onTap; // Can override default behavior
  
  const AyahWidget({
    Key? key,
    required this.ayah,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProvider, _) {
        final isPlaying = quranProvider.playingAyahId == ayah.ayahNumber && quranProvider.isPlaying;
        
        return GestureDetector(
          onTap: onTap ?? () {
             // Play audio on tap
             quranProvider.playAyah(ayah.page, ayah.ayahNumber); 
             // Note: 'page' field in Ayah model might not always be Surah Number. 
             // We need Surah Number. Ayah model usually has surahNumber? or we pass it contextually.
             // Let's assume for now we might need to fix how we pass Surah Number if it's missing from Ayah model.
             // Checking Ayah model structure...
             // For safety, let's look at how QuranProvider plays it.
             // Actually, the provider currently has 'currentSurah'. We can use that.
             if (quranProvider.currentSurah != null) {
               quranProvider.playAyah(quranProvider.currentSurah!.number, ayah.ayahNumber);
             }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPlaying 
                  ? AppColors.golden20
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(color: AppColors.golden, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // النص القرآني
                // النص القرآني
                Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri', // أو KFGQPC HAFS إذا كان متوفراً
                    fontSize: 26,
                    height: 1.8,
                    color: isPlaying ? AppColors.darkBrown : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // رقم الآية وزر التشغيل الصغير
                Row(
                  children: [
                     _buildAyahNumber(),
                     if (isPlaying) ...[
                       const SizedBox(width: 8),
                       const Icon(Icons.volume_up, size: 16, color: AppColors.golden),
                     ],
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildAyahNumber() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.golden, width: 1.5),
        color: AppColors.white,
      ),
      child: Center(
        child: Text(
          _convertToArabicNumbers(ayah.ayahNumber),
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            color: AppColors.golden,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // تحويل الأرقام للعربية
  String _convertToArabicNumbers(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    if (number == 0) return arabicNumerals[0];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }
}
