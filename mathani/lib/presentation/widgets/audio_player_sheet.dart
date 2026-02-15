import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:just_audio/just_audio.dart'; // For LoopMode

class AudioPlayerSheet extends StatelessWidget {
  const AudioPlayerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Glassmorphism-ish background
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Header Info (Surah & Reciter)
              Consumer2<AudioProvider, QuranProvider>(
                builder: (context, audio, quran, _) {
                   String surahName = _getSurahName(quran, audio.currentSurah);
                   
                   return Column(
                     children: [
                       Text(
                         'سورة $surahName',
                         style: TextStyle(
                           fontFamily: 'Amiri',
                           fontSize: 24,
                           fontWeight: FontWeight.bold,
                           color: isDark ? Colors.white : Colors.black87,
                         ),
                       ),
                       const SizedBox(height: 8),
                       GestureDetector(
                         onTap: () => _showReciterSelector(context, audio),
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: AppColors.primary.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text(
                                 audio.currentReciter?.name ?? 'قارئ',
                                 style: const TextStyle(
                                   fontFamily: 'Tajawal',
                                   fontSize: 14,
                                   color: AppColors.primary,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               const SizedBox(width: 4),
                               const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                             ],
                           ),
                         ),
                       ),
                     ],
                   );
                }
              ),
              
              const SizedBox(height: 32),

              // 3. Progress Bar
              Consumer<AudioProvider>(
                builder: (context, audio, _) => _buildProgressBar(context, audio),
              ),

              const SizedBox(height: 24),

              // 4. Main Controls (RTL Optimized)
              Consumer<AudioProvider>(
                builder: (context, audio, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Repeat Mode
                      IconButton(
                        onPressed: () {
                          // Toggle Loop
                          final nextMode = audio.loopMode == LoopMode.off 
                              ? LoopMode.all // Repeat List
                              : (audio.loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
                          audio.setLoopMode(nextMode);
                        },
                        icon: Icon(
                          audio.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          color: audio.loopMode == LoopMode.off ? Colors.grey : AppColors.primary,
                        ),
                      ),
                      
                      const Spacer(),

                      // Previous (Right in RTL context usually, but standard player uses Left-pointing icon for "Back")
                      // User said "Icons appear reversed". 
                      // Standard: <| (Prev/Back)   |> (Next/Forward).
                      // In RTL, Flow is Right -> Left. So "Next" (Forward) should be Left? 
                      // No, traditionally Media is LTR even in RTL apps (Timeline moves LTR).
                      // However, Quran reads RTL. "Next Ayah" is to the Left visually.
                      // Let's force the Logic: 
                      // skip_next usually points Right (>|).
                      // skip_previous usually points Left (|<).
                      // If User wants RTL logic:
                      // Next Ayah = Arrow pointing Left (Following text direction).
                      // Prev Ayah = Arrow pointing Right.
                      
                      // Let's assume standard icons but swap the functionality OR swap the icons positions?
                      // Let's check `Directionality`.
                      
                      // We will place "Next" on the Left and "Prev" on the Right to match Quran reading direction.
                      // AND we will use Mirrored Icons.
                      
                      // Next Button (Left Side)
                      IconButton(
                         icon: Transform.scale(
                           scaleX: -1, // Mirror it
                           child: const Icon(Icons.skip_previous_rounded, size: 36), // Use Prev icon mirrored = Next pointing Left
                         ),
                         onPressed: () {
                           // Logic: Play Next Ayah
                            if (audio.currentSurah != null && audio.currentAyah != null) {
                              audio.playAyah(audio.currentSurah!, audio.currentAyah! + 1);
                           }
                         },
                      ),
                       
                      const SizedBox(width: 24),

                      // Play/Pause
                      GestureDetector(
                        onTap: () {
                          if (audio.isPlaying) {
                            audio.pause();
                          } else {
                            if (audio.currentSurah != null && audio.currentAyah != null) {
                               if (audio.player.processingState == ProcessingState.idle) {
                                  audio.playAyah(audio.currentSurah!, audio.currentAyah!);
                               } else {
                                  audio.play();
                               }
                            }
                          }
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),
                      
                      // Prev Button (Right Side)
                      IconButton(
                         icon: Transform.scale(
                           scaleX: -1, // Mirror it
                           child: const Icon(Icons.skip_next_rounded, size: 36), // Use Next icon mirrored = Prev pointing Right
                         ),
                         onPressed: () {
                            // Logic: Play Prev Ayah
                            if (audio.currentSurah != null && audio.currentAyah! > 1) {
                              audio.playAyah(audio.currentSurah!, audio.currentAyah! - 1);
                           }
                         },
                      ),

                      const Spacer(),

                      // Range / More
                      IconButton(
                        onPressed: () {
                          // Show Range Dialog
                          _showRangeSettings(context, audio);
                        },
                        icon: const Icon(Icons.tune_rounded),
                        color: Colors.grey,
                      ),
                    ],
                  );
                }
              ),
              
              const SizedBox(height: 16),
              
              // 5. Ayah Info
              Consumer<AudioProvider>(
                builder: (context, audio, _) {
                  return Text(
                    'الآية ${audio.currentAyah}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSurahName(QuranProvider quran, int? surahNumber) {
    if (surahNumber == null) return '';
    try {
      final s = quran.surahs.firstWhere((s) => s.number == surahNumber);
      return s.nameArabic;
    } catch (_) {
      return '$surahNumber';
    }
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider audio) {
    final activeColor = AppColors.primary;
    final inactiveColor = Colors.grey.withValues(alpha: 0.3);

    return StreamBuilder<Duration?>(
      stream: audio.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = audio.player.duration ?? Duration.zero;
        final max = total.inMilliseconds.toDouble();
        final value = position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0);

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: activeColor,
                inactiveTrackColor: inactiveColor,
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.2),
                trackShape: const RoundedRectSliderTrackShape(), 
              ),
              child: Slider(
                min: 0.0,
                max: max > 0 ? max : 1.0,
                value: value,
                onChanged: (v) => audio.player.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal')),
                  Text(_formatDuration(total), style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal')),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
  
  void _showReciterSelector(BuildContext context, AudioProvider audio) {
    // Re-use the nice selector you already liked or create a better one
     showModalBottomSheet(
       context: context,
       backgroundColor: Colors.transparent,
       isScrollControlled: true,
       builder: (context) {
         return Container(
           height: MediaQuery.of(context).size.height * 0.7,
           decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
           ),
           child: Column(
             children: [
               const SizedBox(height: 16),
               const Text('اختيار القارئ', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
               const Divider(),
               Expanded(
                 child: ListView.builder(
                   itemCount: audio.reciters.length,
                   itemBuilder: (context, index) {
                     final reciter = audio.reciters[index];
                     final isSelected = audio.currentReciter?.id == reciter.id;
                     return ListTile(
                       title: Text(reciter.name, style: TextStyle(fontFamily: 'Tajawal', fontWeight: isSelected? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : null)),
                     trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                       onTap: () {
                         audio.setReciter(reciter);
                         Navigator.pop(context);
                       },
                     );
                   },
                 ),
               )
             ],
           ),
         );
       }
     );
  }

  void _showRangeSettings(BuildContext context, AudioProvider audio) {
    // Simple placeholder for Range settings
     showModalBottomSheet(
       context: context,
       builder: (context) => Container(
         padding: const EdgeInsets.all(24),
         height: 250,
         child: Column(
           children: [
             const Text('خيارات التلاوة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 24),
             ListTile(
               leading: const Icon(Icons.repeat),
               title: const Text('تكرار هذه الآية', style: TextStyle(fontFamily: 'Tajawal')),
               trailing: Switch(
                 value: audio.loopMode == LoopMode.one,
                 onChanged: (v) {
                   audio.setLoopMode(v ? LoopMode.one : LoopMode.off);
                   Navigator.pop(context);
                 },
               ),
             ),
             ListTile(
               leading: const Icon(Icons.format_list_numbered),
               title: const Text('تلاوة مستمرة للسورة كاملة', style: TextStyle(fontFamily: 'Tajawal')),
               trailing: Switch(
                 value: audio.loopMode == LoopMode.all,
                 onChanged: (v) {
                   // Logic: Enable continuous
                   audio.setLoopMode(v ? LoopMode.all : LoopMode.off);
                   Navigator.pop(context);
                 },
               ),
             )
           ],
         ),
       ),
     );
  }
}
