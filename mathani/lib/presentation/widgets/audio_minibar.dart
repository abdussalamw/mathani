import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/widgets/audio_player_sheet.dart';
import 'package:mathani/presentation/providers/ui_provider.dart'; // Added
import 'package:mathani/data/providers/mushaf_navigation_provider.dart'; // Added

class AudioMinibar extends StatelessWidget {
  const AudioMinibar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        // Smart Visibility: Logic based on AudioProvider.showMinibar
        if (!audio.showMinibar) return const SizedBox.shrink();

        final hasContext = audio.currentSurah != null;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AudioPlayerSheet(),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  // 1. Play/Pause
                _ControlButton(
                   // If no context, show 'Play' icon (to start from page), not headphones which implies passive mode
                   icon: audio.isPlaying ? Icons.pause : Icons.play_arrow, 
                   onPressed: () {
                     if (audio.isPlaying) {
                       audio.pause();
                     } else if (hasContext) {
                       audio.play();
                     } else {
                       // No context? Start from beginning of current page!
                       final ui = context.read<UiProvider>();
                       final nav = context.read<MushafNavigationProvider>();
                       final page = ui.currentMushafPage;
                       final info = nav.getPageInfo(page);
                       
                       if (info != null) {
                         // Prefer startSurah/startAyah
                         // Note: PageInfo usually has accurate start/end
                         final surah = info.startSurah;
                         final ayah = info.startAyah > 0 ? info.startAyah : 1;
                         audio.playAyah(surah, ayah);
                       } else {
                         // Fallback: Open Sheet
                         showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AudioPlayerSheet(),
                        );
                       }
                     }
                   },
                   isPrimary: true,
                ),
                
                const SizedBox(width: 8),

                // 2. Info (Middle) - Compacted
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<QuranProvider>(
                        builder: (context, quran, _) {
                          String surahName = _getSurahName(quran, audio.currentSurah);
                          return Text(
                            hasContext ? 'سورة $surahName (${audio.currentAyah})' : 'تلاوة القرآن',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                      Text(
                        audio.currentReciter?.name ?? '',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                
                // 3. Navigation Controls
                if (hasContext) ...[
                  // Prev
                  _SmallButton(
                    icon: Icons.skip_next_rounded, // Mirrored Logic: Skip Next (Points Right) = Previous Ayah
                    onPressed: () => audio.playAyah(audio.currentSurah!, audio.currentAyah! - 1),
                  ),
                  // Next
                  _SmallButton(
                    icon: Icons.skip_previous_rounded, // Mirrored Logic: Skip Prev (Points Left) = Next Ayah
                    onPressed: () => audio.playAyah(audio.currentSurah!, audio.currentAyah! + 1),
                  ),
                  // Toggle Repeat Ayah
                  _SmallButton(
                    icon: Icons.repeat_one_rounded,
                    onPressed: () {
                      audio.setAyahRepeatLimit(audio.ayahRepeatLimit == 1 ? 999 : 1);
                    },
                    color: audio.ayahRepeatLimit > 1 ? AppColors.primary : Colors.grey[400],
                  ),
                ],

                const SizedBox(width: 8),
                
                // 4. Close (Stop & Hide)
                _SmallButton(
                  icon: Icons.close_rounded,
                  onPressed: () => audio.stopAndHide(),
                  isCircular: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSurahName(QuranProvider quran, int? num) {
    if (num == null) return '';
    try {
      return quran.surahs.firstWhere((s) => s.number == num).nameArabic;
    } catch (_) {
      return '$num';
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ControlButton({required this.icon, required this.onPressed, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 24),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isCircular;

  const _SmallButton({required this.icon, required this.onPressed, this.color, this.isCircular = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color ?? Colors.grey[500], size: 22),
      ),
    );
  }
}
