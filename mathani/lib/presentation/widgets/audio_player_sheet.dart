import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';

class AudioPlayerSheet extends StatelessWidget {
  const AudioPlayerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audio = context.watch<AudioProvider>();
    final quran = context.watch<QuranProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 2. Header - show active or reading Surah
                  Builder(
                    builder: (_) {
                      final activeSurah = audio.currentSurah ?? quran.readingSurah;
                      return Text(
                        'سورة ${_getSurahName(quran, activeSurah)}',
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _ReciterBadge(audio: audio),

                  const SizedBox(height: 20),

                  // 3. Main Controls (no progress bar)
                  _MainControls(audio: audio, quran: quran),

                  const SizedBox(height: 20),

                  // 4. Advanced Options
                  _AdvancedOptions(audio: audio, quran: quran),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _ReciterBadge extends StatelessWidget {
  final AudioProvider audio;
  const _ReciterBadge({required this.audio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReciterSelector(context, audio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              audio.currentReciter?.name ?? 'قارئ',
              style: const TextStyle(fontFamily: 'Tajawal', color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showReciterSelector(BuildContext context, AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReciterSelectorSheet(audio: audio),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioProvider audio;
  const _ProgressBar({required this.audio});

  @override
  Widget build(BuildContext context) {
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
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                min: 0.0,
                max: max > 0 ? max : 1.0,
                value: value,
                onChanged: (v) => audio.player.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(fontSize: 11, fontFamily: 'Tajawal')),
                  Text(_formatDuration(total), style: const TextStyle(fontSize: 11, fontFamily: 'Tajawal')),
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
}

class _MainControls extends StatelessWidget {
  final AudioProvider audio;
  final QuranProvider quran;
  const _MainControls({required this.audio, required this.quran});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Prev Ayah
        IconButton(
          onPressed: () {
            if (audio.player.hasPrevious) {
               audio.player.seekToPrevious();
            } else if (audio.currentSurah != null && audio.currentAyah != null && audio.currentAyah! > 1) {
               audio.playAyah(audio.currentSurah!, audio.currentAyah! - 1);
            }
          },
          icon: const Icon(Icons.skip_next_rounded, size: 36), // Mirrored
        ),

        // Stop (square) - إيقاف كامل
        IconButton(
          onPressed: () {
            audio.stop();
            Navigator.of(context).pop(); // أغلق الشاشة
          },
          icon: const Icon(Icons.stop_rounded, size: 36, color: Colors.redAccent),
          tooltip: 'إيقاف',
        ),

        // Play/Pause
        GestureDetector(
          onTap: () {
            if (audio.isPlaying) {
              audio.pause();
            } else if (audio.currentSurah != null) {
              audio.resumeOrPlay();
            } else {
              // ابدأ من موقع القراءة الحالي في المصحف
              final surah = quran.readingSurah;
              final ayah = quran.readingAyah > 0 ? quran.readingAyah : 1;
              audio.playAyah(surah, ayah);
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: audio.isLoading
              ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 48),
          ),
        ),

        // Next Ayah
        IconButton(
          onPressed: () {
             if (audio.player.hasNext) {
               audio.player.seekToNext();
             } else if (audio.currentSurah != null && audio.currentAyah != null) {
               audio.playAyah(audio.currentSurah!, audio.currentAyah! + 1);
             }
          },
          icon: const Icon(Icons.skip_previous_rounded, size: 36), // Mirrored
        ),
      ],
    );
  }
}

class _AdvancedOptions extends StatefulWidget {
  final AudioProvider audio;
  final QuranProvider quran;
  const _AdvancedOptions({required this.audio, required this.quran});

  @override
  State<_AdvancedOptions> createState() => _AdvancedOptionsState();
}

class _AdvancedOptionsState extends State<_AdvancedOptions> {
  late int startSurah;
  late int startAyah;
  late int endSurah;
  late int endAyah;

  @override
  void initState() {
    super.initState();
    
    // استخدم QuranProvider كمصدر موثوق للسورة والآية الحالية
    final quran = context.read<QuranProvider>();
    final defaultSurah = widget.audio.currentSurah ?? quran.readingSurah;
    final defaultAyah = widget.audio.currentAyah ?? quran.readingAyah;

    startSurah = widget.audio.startSurah ?? defaultSurah;
    startAyah = widget.audio.startAyah ?? defaultAyah;
    endSurah = widget.audio.endSurah ?? defaultSurah;
    endAyah = widget.audio.endAyah ?? defaultAyah + 10;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.golden.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('خيارات التلاوة والحفظ', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 32),
          
          // 1. Range From
          _buildRangeRow('من:', startSurah, startAyah, (s, a) {
            setState(() { startSurah = s; startAyah = a; });
          }),
          const SizedBox(height: 16),
          
          // 2. Range To
          _buildRangeRow('إلى:', endSurah, endAyah, (s, a) {
            setState(() { endSurah = s; endAyah = a; });
          }),

          const SizedBox(height: 24),

          // 3. Repetition Counters
          Row(
            children: [
              Expanded(child: _CounterField(
                label: 'تكرار الآية', 
                value: widget.audio.ayahRepeatLimit, 
                onChanged: (v) => widget.audio.setAyahRepeatLimit(v),
              )),
              const SizedBox(width: 16),
              Expanded(child: _CounterField(
                label: 'تكرار المقطع', 
                value: widget.audio.rangeRepeatLimit, 
                onChanged: (v) => widget.audio.setRangeRepeatLimit(v),
              )),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 widget.audio.playRange(
                   startSurah: startSurah, 
                   startAyah: startAyah, 
                   endSurah: endSurah, 
                   endAyah: endAyah
                 );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('بدء التكرار المحدد', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  int _getAyahCountForSurah(int surahNumber) {
    try {
      return widget.quran.surahs.firstWhere((s) => s.number == surahNumber).numberOfAyahs;
    } catch (_) {
      return 286; // fallback
    }
  }

  Widget _buildRangeRow(String label, int surah, int ayah, Function(int, int) onChanged) {
    final maxAyahs = _getAyahCountForSurah(surah);
    final clampedAyah = ayah.clamp(1, maxAyahs);
    
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13))),
        
        // Surah Selector
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: surah,
                isExpanded: true,
                items: widget.quran.surahs.map((s) => DropdownMenuItem(
                  value: s.number,
                  child: Text(s.nameArabic, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                )).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val, 1); // إعادة الآية لـ 1 عند تغيير السورة
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),

        // Ayah Selector - ★ ديناميكي حسب عدد آيات السورة
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: clampedAyah,
                isExpanded: true,
                items: List.generate(maxAyahs, (i) => i + 1).map((i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                )).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(surah, val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _CounterField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => value > 1 ? onChanged(value - 1) : null),
              Text('$value', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => onChanged(value + 1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReciterSelectorSheet extends StatelessWidget {
  final AudioProvider audio;
  const _ReciterSelectorSheet({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  title: Text(reciter.name, style: TextStyle(fontFamily: 'Tajawal', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : null)),
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
}
