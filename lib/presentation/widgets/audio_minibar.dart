import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/ui_provider.dart'; // Added

// Added

class AudioMinibar extends StatelessWidget {
  const AudioMinibar({super.key});

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
            context.read<UiProvider>().toggleFullAudioPlayer();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E20) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.brandGold.withValues(alpha: 0.2),
                width: 1,
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
                      // استئناف من حيث توقف
                      audio.resumeOrPlay();
                    } else {
                      // ★ ابدأ من موقع القراءة الحالي (readingSurah مُحدّث دائماً)
                      final quran = context.read<QuranProvider>();
                      final surah = quran.readingSurah;
                      final ayah = quran.readingAyah > 0
                          ? quran.readingAyah
                          : 1;
                      audio.playAyah(surah, ayah);
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
                          // ★ استخدم readingSurah كـ fallback إذا currentSurah فارغ
                          final displaySurah =
                              audio.currentSurah ?? quran.readingSurah;
                          String surahName = _getSurahName(quran, displaySurah);
                          final displayAyah =
                              audio.currentAyah ?? quran.readingAyah;
                          return Text(
                            'سورة $surahName ($displayAyah)',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final hasError =
                              audio.lastError != null &&
                              !audio.isPlaying &&
                              !audio.isLoading;
                          return Text(
                            hasError
                                ? audio.lastError!
                                : (audio.currentReciter?.name ?? ''),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: hasError ? 9 : 10,
                              color: hasError ? Colors.red : Colors.grey[500],
                              fontWeight: hasError
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Navigation Controls
                if (hasContext) ...[
                  // Prev (Right arrow → plays previous Ayah)
                  _SmallButton(
                    icon: Icons.skip_next_rounded, // Mirrored icon
                    onPressed: () => audio.skipRelative(-1),
                  ),
                  // Next (Left arrow → plays next Ayah)
                  _SmallButton(
                    icon: Icons.skip_previous_rounded, // Mirrored icon
                    onPressed: () => audio.skipRelative(1),
                  ),
                  // Toggle Repeat Ayah: 1 → 2 → 3 → ... → 10 → 1
                  _RepeatButton(audio: audio),
                ],

                const SizedBox(width: 8),

                // 4. Close (Stop & Hide)
                _SmallButton(
                  icon: Icons.close_rounded,
                  onPressed: () => audio.stopAndHide(),
                  color: isDark ? Colors.white38 : Colors.grey[400],
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

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.brandGold : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.brandGold,
          size: 24,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isCircular;

  const _SmallButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.isCircular = false,
  });

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

/// زر التكرار الدوري: 1 → 2 → 3 → ... → 10 → 1
class _RepeatButton extends StatelessWidget {
  final AudioProvider audio;
  const _RepeatButton({required this.audio});

  @override
  Widget build(BuildContext context) {
    final count = audio.ayahRepeatLimit;
    final isActive = count > 1;
    return InkWell(
      onTap: () {
        // دورة: 1→2→...→10→1
        final next = count >= 10 ? 1 : count + 1;
        audio.setAyahRepeatLimit(next);
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.repeat_one_rounded,
              color: isActive ? AppColors.primary : Colors.grey[400],
              size: 22,
            ),
            if (isActive)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${count}x',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
