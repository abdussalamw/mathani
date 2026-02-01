import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/core/constants/app_colors.dart';

class AudioMinibar extends StatelessWidget {
  const AudioMinibar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        if (audio.currentSurah == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2416) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.golden.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  if (audio.isPlaying) {
                    audio.pause();
                  } else {
                    audio.play();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audio.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Text Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جاري الاستماع',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    Consumer<QuranProvider>(
                      builder: (context, quran, _) {
                        String surahName = audio.currentSurah.toString();
                        if (quran.surahs.isNotEmpty) {
                          try {
                            final s = quran.surahs.firstWhere((s) => s.number == audio.currentSurah);
                            surahName = s.nameArabic;
                          } catch (_) {}
                        }
                        
                        return Text(
                          'سورة $surahName - آية ${audio.currentAyah}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.golden,
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
              
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.red),
                onPressed: () => audio.stop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
