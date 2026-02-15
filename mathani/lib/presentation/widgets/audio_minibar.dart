import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/widgets/audio_player_sheet.dart';

class AudioMinibar extends StatelessWidget {
  const AudioMinibar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        // Only hide if we have absolutely no reciter info (rare)
        if (audio.reciters.isEmpty) return const SizedBox.shrink();

        final hasContext = audio.currentSurah != null;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // Allow transparency and height control
              backgroundColor: Colors.transparent,
              builder: (_) => const AudioPlayerSheet(),
            );
          },
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Added more bottom margin
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2416) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.golden.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Play/Pause or Listen Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      !hasContext ? Icons.headphones_rounded : (audio.isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasContext) ...[
                          Text(
                            audio.currentReciter?.name ?? 'قارئ',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Consumer<QuranProvider>(
                          builder: (context, quran, _) {
                            String surahName = hasContext ? audio.currentSurah.toString() : '';
                            if (hasContext && quran.surahs.isNotEmpty) {
                              try {
                                final s = quran.surahs.firstWhere((s) => s.number == audio.currentSurah);
                                surahName = s.nameArabic;
                              } catch (_) {}
                            }
                            
                            return Text(
                              hasContext ? 'سورة $surahName - آية ${audio.currentAyah}' : 'ابدأ الاستماع والتلاوة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: hasContext ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  
                  // Expand Icon
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: !hasContext ? AppColors.primary : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  
                  // Close Button
                  GestureDetector(
                    onTap: () => Provider.of<UiProvider>(context, listen: false).setShowAudioMinibar(false),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}
