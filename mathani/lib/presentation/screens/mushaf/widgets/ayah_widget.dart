import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/settings_provider.dart';
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
    return Consumer3<QuranProvider, AudioProvider, SettingsProvider>(
      builder: (context, quranProvider, audioProvider, settingsProvider, _) {
        // Check if this ayah is currently playing
        final isPlaying = audioProvider.isPlaying && 
                          audioProvider.currentSurah == ayah.page && // Note: verifying valid Surah ID usually corresponds to page in some models, but let's check currentSurah from provider
                          audioProvider.currentAyah == ayah.ayahNumber;
        
        // Better matching: assume ayah.page is actually surah number based on previous code usage
        // or check quranProvider.currentSurah?.number
        final currentSurahNum = quranProvider.currentSurah?.number ?? ayah.page; 
        
        final isActuallyPlaying = audioProvider.isPlaying &&
                                  audioProvider.currentSurah == currentSurahNum &&
                                  audioProvider.currentAyah == ayah.ayahNumber;

        return GestureDetector(
          onTap: () {
             // Find Surah to get total ayahs
             int? totalAyahs;
             try {
               final surahObj = quranProvider.surahs.firstWhere((s) => s.number == currentSurahNum);
               totalAyahs = surahObj.numberOfAyahs;
             } catch (_) {}

             audioProvider.playAyah(
               currentSurahNum, 
               ayah.ayahNumber,
             );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActuallyPlaying 
                  ? AppColors.golden.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActuallyPlaying
                  ? Border.all(color: AppColors.golden, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'KFGQPC_HAFS',
                    fontSize: 26,
                    height: 1.8,
                    color: isActuallyPlaying ? AppColors.darkBrown : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                     _buildAyahNumber(),
                     if (isActuallyPlaying) ...[
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
            fontFamily: 'KFGQPC_HAFS',
            fontSize: 16,
            color: AppColors.golden,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
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
