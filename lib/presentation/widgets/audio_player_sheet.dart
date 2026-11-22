import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';

class AudioPlayerSheet extends StatelessWidget {
  const AudioPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audio = context.watch<AudioProvider>();
    final quran = context.watch<QuranProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    final ui = context.read<UiProvider>();

    return Container(
      height: screenHeight * 0.5,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : AppColors.brandBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Handle & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 40,
                  ), // Placeholder to keep handle centered
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق مشغّل التلاوة',
                    onPressed: () => ui.setShowFullAudioPlayer(false),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // 2. Header & Reciter Info
                    Builder(
                      builder: (_) {
                        final activeSurah =
                            audio.currentSurah ?? quran.readingSurah;
                        return Column(
                          children: [
                            Text(
                              'سورة ${_getSurahName(quran, activeSurah)}',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slateText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ReciterBadge(audio: audio),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 3. Main Controls
                    _MainControls(audio: audio, quran: quran, ui: ui),

                    const SizedBox(height: 16),

                    // 4. Advanced Options
                    _AdvancedOptions(audio: audio, quran: quran),
                    if (audio.upcomingTracks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'الآيات التالية',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...audio.upcomingTracks.map(
                        (entry) => ListTile(
                          leading: const Icon(
                            Icons.queue_music_rounded,
                            color: AppColors.brandGold,
                          ),
                          title: Text(entry.item.title),
                          subtitle: Text(entry.item.artist ?? ''),
                          onTap: () => audio.skipToTrack(entry.index),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showReciterSelector(context, audio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.brandGold.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 14,
              color: AppColors.brandGold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                audio.currentReciter?.name ?? 'اختر القارئ',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppColors.brandGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.brandGold,
            ),
          ],
        ),
      ),
    );
  }
}

void _showReciterSelector(BuildContext context, AudioProvider audio) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReciterSelectorSheet(audio: audio),
  );
}

class _MainControls extends StatelessWidget {
  final AudioProvider audio;
  final QuranProvider quran;
  final UiProvider ui;
  const _MainControls({
    required this.audio,
    required this.quran,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          // 1. Speed
          _CircleActionBtn(
            icon: Icons.speed_rounded,
            tooltip: 'تغيير سرعة التلاوة',
            onPressed: () {
              final current = audio.player.speed;
              final next = current >= 2.0 ? 1.0 : current + 0.25;
              audio.player.setSpeed(next);
            },
            label: '${audio.player.speed}x',
          ),

          // 2. Prev
          _CircleActionBtn(
            icon: Icons.skip_next_rounded,
            tooltip: 'الآية السابقة',
            onPressed: () => audio.skipRelative(-1),
          ),

          // 3. Play/Pause (Central)
          Semantics(
            button: true,
            label: audio.isPlaying ? 'إيقاف التلاوة مؤقتًا' : 'تشغيل التلاوة',
            child: InkWell(
              onTap: () {
                if (audio.isPlaying) {
                  audio.pause();
                } else if (audio.currentSurah != null) {
                  audio.resumeOrPlay();
                } else {
                  final surah = quran.readingSurah;
                  final ayah = quran.readingAyah > 0 ? quran.readingAyah : 1;
                  audio.playAyah(surah, ayah);
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGold.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: audio.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Icon(
                        audio.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ),
          // 4. Next
          _CircleActionBtn(
            icon: Icons.skip_previous_rounded,
            tooltip: 'الآية التالية',
            onPressed: () => audio.skipRelative(1),
          ),

          // 5. Stop (Changed icon to be more unique for test)
          _CircleActionBtn(
            icon: Icons.power_settings_new_rounded,
            tooltip: 'إيقاف التلاوة',
            color: Colors.redAccent.withValues(alpha: 0.7),
            onPressed: () {
              audio.stop();
              ui.setShowFullAudioPlayer(false);
            },
          ),
        ],
      ),
    );
  }
}

class _CircleActionBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? label;

  const _CircleActionBtn({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[50],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 20,
              color: color ?? (isDark ? Colors.white70 : AppColors.slateText),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    startSurah =
        widget.audio.startSurah ??
        widget.audio.currentSurah ??
        widget.quran.readingSurah;
    startAyah =
        widget.audio.startAyah ??
        widget.audio.currentAyah ??
        widget.quran.readingAyah;
    if (startAyah == 0) startAyah = 1;

    endSurah = widget.audio.endSurah ?? startSurah;
    endAyah = widget.audio.endAyah ?? startAyah;
  }

  int _getAyahCountForSurah(int surahNumber) {
    try {
      return widget.quran.surahs
          .firstWhere((s) => s.number == surahNumber)
          .numberOfAyahs;
    } catch (_) {
      return 286;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.repeat_rounded, color: AppColors.brandGold, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'نطاق التلاوة والتكرار',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Range Selectors
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildRangeItemCompact('من:', startSurah, startAyah, (s, a) {
                  setState(() {
                    startSurah = s;
                    startAyah = a;
                  });
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, indent: 40, color: Colors.grey),
                ),
                _buildRangeItemCompact('إلى:', endSurah, endAyah, (s, a) {
                  setState(() {
                    endSurah = s;
                    endAyah = a;
                  });
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Repetition Row
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final width = stacked
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildCounter(
                      'تكرار الآية',
                      widget.audio.ayahRepeatLimit,
                      (val) {
                        widget.audio.setAyahRepeatLimit(val);
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildCounter(
                      'تكرار المقطع',
                      widget.audio.rangeRepeatLimit,
                      (val) {
                        widget.audio.setRangeRepeatLimit(val);
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.audio.isLoading
                  ? null
                  : () {
                      widget.audio.playRange(
                        startSurah: startSurah,
                        startAyah: startAyah,
                        endSurah: endSurah,
                        endAyah: endAyah,
                      );
                    },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text(
                'بدء التكرار المحدد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGold,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (widget.audio.startSurah != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.audio.isLoading
                    ? null
                    : () => widget.audio.playRange(
                        startSurah: startSurah,
                        startAyah: startAyah,
                        endSurah: endSurah,
                        endAyah: endAyah,
                        preserveCurrentPosition: true,
                      ),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('تطبيق التغييرات مع حفظ موضع التلاوة'),
              ),
            ),
          ],
          if (widget.audio.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.audio.lastError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRangeItemCompact(
    String label,
    int surah,
    int ayah,
    Function(int, int) onChanged,
  ) {
    final maxAyahs = _getAyahCountForSurah(surah);
    final clampedAyah = ayah.clamp(1, maxAyahs);

    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildDropdown<int>(
            value: surah,
            items: widget.quran.surahs
                .map(
                  (s) => DropdownMenuItem(
                    value: s.number,
                    child: Text(
                      s.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => val != null ? onChanged(val, 1) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildDropdown<int>(
            value: clampedAyah,
            items: List.generate(maxAyahs, (i) => i + 1)
                .map(
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '$i',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => val != null ? onChanged(surah, val) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: AppColors.brandGold,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterBtn(
                icon: Icons.remove,
                tooltip: 'تقليل $label',
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              const SizedBox(width: 12),
              Text(
                '$value',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              _CounterBtn(
                icon: Icons.add,
                tooltip: 'زيادة $label',
                onPressed: value < 20 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _CounterBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.brandGold.withValues(alpha: 0.1),
      ),
      icon: Icon(icon, size: 16, color: AppColors.brandGold),
    );
  }
}

class _ReciterSelectorSheet extends StatelessWidget {
  final AudioProvider audio;
  const _ReciterSelectorSheet({required this.audio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : AppColors.brandBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'اختيار القارئ',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: audio.reciters.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 70,
                color: Colors.grey.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final reciter = audio.reciters[index];
                final isSelected = audio.currentReciter?.id == reciter.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandGold
                          : (isDark ? Colors.white10 : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        reciter.name.substring(0, 1),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey[600]),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    reciter.name,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.brandGold
                          : (isDark ? Colors.white : AppColors.slateText),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.brandGold,
                        )
                      : null,
                  onTap: () {
                    audio.setReciter(reciter);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
