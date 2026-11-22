import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/data/models/recitation_result.dart';

String recitationSurahName(
  BuildContext context,
  int number, {
  String fallback = '',
}) {
  if (fallback.trim().isNotEmpty) return fallback;
  final quran = context.read<QuranProvider?>();
  if (quran != null) {
    for (final surah in quran.surahs) {
      if (surah.number == number && surah.nameArabic.isNotEmpty) {
        return surah.nameArabic;
      }
    }
  }
  return 'السورة $number';
}

String recitationRangeLabel(BuildContext context, RecitationResult result) {
  final start = result.startLocation;
  final end = result.endLocation;
  if (start.surahNumber == end.surahNumber) {
    return start.ayahNumber == end.ayahNumber
        ? 'الآية ${start.ayahNumber}'
        : 'الآيات ${start.ayahNumber}–${end.ayahNumber}';
  }
  final startName = recitationSurahName(
    context,
    start.surahNumber,
    fallback: result.surahName,
  );
  final endName = recitationSurahName(context, end.surahNumber);
  return '$startName ${start.ayahNumber} – $endName ${end.ayahNumber}';
}

/// شاشة النتائج — تلوين كلمة بكلمة مع إحصائيات
class RecitationResultView extends StatefulWidget {
  const RecitationResultView({
    super.key,
    this.resultOverride,
    this.focusedWord,
    this.onReplay,
    this.onOpenHistory,
  });

  final RecitationResult? resultOverride;
  final WordResult? focusedWord;
  final VoidCallback? onReplay;
  final VoidCallback? onOpenHistory;

  @override
  State<RecitationResultView> createState() => _RecitationResultViewState();
}

class _RecitationResultViewState extends State<RecitationResultView> {
  RecitationResult? _updatedOverride;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();
    final supplied = _updatedOverride ?? widget.resultOverride;
    final sessionId = supplied?.sessionId;
    final saved = sessionId == null
        ? null
        : provider.allSessions
              .where((session) => session.id == sessionId)
              .firstOrNull;
    final result = saved == null
        ? supplied ?? provider.currentResult
        : RecitationResult.fromSession(saved);

    if (result == null) {
      return const Center(child: Text('لا توجد نتائج'));
    }

    final scheme = Theme.of(context).colorScheme;
    final verses = result.wordsByVerse.entries.toList();
    final hasActions =
        widget.resultOverride == null ||
        widget.onReplay != null ||
        widget.onOpenHistory != null;
    final summary = [
      _buildScoreCard(context, result, isDark),
      if (widget.focusedWord case final word?)
        _buildFocusedWord(context, result, word),
      if (result.reviewItems.isNotEmpty) _buildReviewSummary(context, result),
      if (verses.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'التفصيل آية بآية',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
        child: SafeArea(
          child: Column(
            children: [
              // ─── شريط العلوي ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: scheme.onSurface,
                      ),
                      tooltip: 'رجوع',
                      onPressed: widget.resultOverride == null
                          ? provider.goToSetup
                          : () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        'نتيجة التسميع',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount:
                      summary.length + verses.length + (hasActions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < summary.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: summary[index],
                      );
                    }
                    final verseIndex = index - summary.length;
                    if (verseIndex < verses.length) {
                      return _buildVerse(
                        context,
                        result,
                        verses[verseIndex],
                        isDark,
                      );
                    }
                    return _buildActions(context, provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    RecitationResult result,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;
    Color scoreColor;
    if (result.accuracy >= 0.85) {
      scoreColor = AppColors.success;
    } else if (result.accuracy >= 0.60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.1),
            scoreColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // النسبة المئوية
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result.accuracy),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: scoreColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (result.hasDismissedReviewItems)
            Text(
              'دقة التحليل الأصلية',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          Text(
            result.overallGrade,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.startLocation.surahNumber == result.endLocation.surahNumber
                ? '${recitationSurahName(context, result.surahNumber, fallback: result.surahName)} · ${recitationRangeLabel(context, result)}'
                : recitationRangeLabel(context, result),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          if (result.gradedWords > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${result.correctWords} صحيحة من ${result.gradedWords} كلمة مقيّمة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSummary(BuildContext context, RecitationResult result) {
    final counts = <RecitationReviewKind, int>{};
    var dismissedCount = 0;
    for (final item in result.reviewItems) {
      if (result.isReviewItemDismissed(item)) {
        dismissedCount += item.count;
        continue;
      }
      counts.update(
        item.kind,
        (count) => count + item.count,
        ifAbsent: () => item.count,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kind in RecitationReviewKind.values)
          if (counts[kind] case final count?)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kind.isIssue
                    ? scheme.errorContainer
                    : scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${kind.label} · $count',
                style: TextStyle(
                  color: kind.isIssue
                      ? scheme.onErrorContainer
                      : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        if (dismissedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('مستبعدة · $dismissedCount'),
          ),
      ],
    );
  }

  Widget _buildFocusedWord(
    BuildContext context,
    RecitationResult result,
    WordResult word,
  ) {
    final sameVerse = result.wordsByVerse[word.location] ?? [word];
    final fullVerse =
        word.effectiveReviewKind == RecitationReviewKind.skippedAyah;
    final nearby = sameVerse.where(
      (candidate) =>
          fullVerse || (candidate.wordIndex - word.wordIndex).abs() <= 2,
    );
    final surah = recitationSurahName(
      context,
      word.surahNumber,
      fallback: result.surahNumber == word.surahNumber ? result.surahName : '',
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$surah · الآية ${word.ayahNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final item in nearby)
                  _buildWordChip(context, item, result),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerse(
    BuildContext context,
    RecitationResult result,
    MapEntry<RecitationVerseLocation, List<WordResult>> entry,
    bool isDark,
  ) {
    final location = entry.key;
    final surah = recitationSurahName(
      context,
      location.surahNumber,
      fallback: result.surahNumber == location.surahNumber
          ? result.surahName
          : '',
    );
    final skipped = entry.value.any(
      (word) =>
          word.effectiveReviewKind == RecitationReviewKind.skippedAyah &&
          !result.isWordReviewDismissed(word),
    );
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$surah · الآية ${location.ayahNumber}',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (skipped) ...[
              const SizedBox(height: 4),
              Text(
                RecitationReviewKind.skippedAyah.label,
                style: TextStyle(color: scheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final word in entry.value)
                  _buildWordChip(context, word, result),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(
    BuildContext context,
    WordResult word,
    RecitationResult result,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final kind = word.effectiveReviewKind;
    final dismissed = result.isWordReviewDismissed(word);
    final accent = dismissed
        ? scheme.onSurfaceVariant
        : switch (word.verdict) {
            WordVerdict.correct =>
              scheme.brightness == Brightness.dark
                  ? AppColors.success
                  : const Color(0xFF217346),
            WordVerdict.acceptable => scheme.onSurface,
            WordVerdict.incorrect || WordVerdict.skipped => scheme.error,
            WordVerdict.unconfirmed => scheme.onSurfaceVariant,
          };
    final wordLabel = _displayWord(word);
    return Semantics(
      button: true,
      child: Tooltip(
        message: dismissed ? 'تنبيه مستبعد' : _getTooltipText(word),
        preferBelow: false,
        child: Material(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showComparisonDialog(context, word, result),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wordLabel,
                    style: TextStyle(
                      fontFamily: 'KFGQPC_HAFS',
                      fontSize: 18,
                      color: accent,
                    ),
                  ),
                  if (dismissed ||
                      (kind != null &&
                          kind != RecitationReviewKind.skippedAyah))
                    Text(
                      dismissed ? 'مستبعد' : kind!.label,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayWord(WordResult word) {
    if (word.effectiveReviewKind == RecitationReviewKind.addedWord) {
      return word.spokenWord.isEmpty ? 'إضافة' : word.spokenWord;
    }
    return word.expectedWord.isEmpty ? 'موضع المطابقة' : word.expectedWord;
  }

  Future<void> _showComparisonDialog(
    BuildContext context,
    WordResult word,
    RecitationResult result,
  ) async {
    final provider = context.read<RecitationProvider>();
    final path = result.audioPath;
    var hasUserClip = false;
    if (path != null &&
        path.isNotEmpty &&
        word.startTimeMs != null &&
        word.endTimeMs != null &&
        word.startTimeMs! >= 0 &&
        word.endTimeMs! > word.startTimeMs!) {
      hasUserClip = await File(path).exists();
    }
    if (!context.mounted) return;

    final name = recitationSurahName(
      context,
      word.surahNumber,
      fallback: result.surahNumber == word.surahNumber ? result.surahName : '',
    );
    final kind = word.effectiveReviewKind;
    final reviewItem = result.reviewIssueForWord(word);
    var playingUserClip = false;
    var dialogResult = result;
    var saving = false;
    var saveFailed = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final scheme = Theme.of(context).colorScheme;
          final dismissed =
              reviewItem != null &&
              dialogResult.isReviewItemDismissed(reviewItem);
          return AlertDialog(
            scrollable: true,
            title: Text('$name · الآية ${word.ayahNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayWord(word),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'KFGQPC_HAFS',
                    fontSize: 36,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_getTooltipText(word), textAlign: TextAlign.center),
                if (dismissed)
                  Text(
                    'مستبعد من إحصاء الأخطاء',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                if (saveFailed)
                  Text(
                    'تعذّر حفظ التعديل. حاول مرة أخرى.',
                    style: TextStyle(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                if (kind == RecitationReviewKind.addedWord &&
                    word.expectedWord.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'قبل «${word.expectedWord}»',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 14),
                if (hasUserClip && path != null) ...[
                  _buildComparisonPlayRow(
                    context: context,
                    label: 'مقطع الكلمة من تسجيلك',
                    icon: Icons.mic_rounded,
                    color: AppColors.primary,
                    isPlaying: playingUserClip,
                    onPlay: () async {
                      setDialogState(() => playingUserClip = true);
                      try {
                        await provider.stopSheikhAudio();
                        if (!context.mounted || !playingUserClip) return;
                        await provider.playUserWordAudio(path, word);
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => playingUserClip = false);
                        }
                      }
                    },
                    onStop: () {
                      setDialogState(() => playingUserClip = false);
                      provider.stopUserAudio();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                AnimatedBuilder(
                  animation: provider,
                  builder: (context, _) => _buildComparisonPlayRow(
                    context: context,
                    label: 'تلاوة الآية بصوت المنشاوي',
                    icon: Icons.record_voice_over_rounded,
                    color: AppColors.brandGold,
                    isPlaying: provider.isSheikhPlaying,
                    onPlay: () async {
                      setDialogState(() => playingUserClip = false);
                      await provider.stopUserAudio();
                      if (!context.mounted) return;
                      await provider.playSheikhAyah(
                        word.surahNumber,
                        word.ayahNumber,
                      );
                    },
                    onStop: provider.stopSheikhAudio,
                  ),
                ),
              ],
            ),
            actions: [
              if (reviewItem != null)
                TextButton.icon(
                  icon: Icon(
                    dismissed
                        ? Icons.undo_rounded
                        : Icons.remove_circle_outline,
                  ),
                  label: Text(
                    dismissed ? 'إعادة احتساب التنبيه' : 'استبعاد التنبيه',
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() {
                            saving = true;
                            saveFailed = false;
                          });
                          try {
                            final updated = await provider
                                .setReviewItemDismissed(
                                  dialogResult,
                                  reviewItem,
                                  dismissed: !dismissed,
                                );
                            if (mounted && widget.resultOverride != null) {
                              setState(() => _updatedOverride = updated);
                            }
                            if (context.mounted) {
                              setDialogState(() {
                                dialogResult = updated;
                                saving = false;
                              });
                            }
                          } catch (_) {
                            if (context.mounted) {
                              setDialogState(() {
                                saving = false;
                                saveFailed = true;
                              });
                            }
                          }
                        },
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
    await provider.stopUserAudio();
    await provider.stopSheikhAudio();
  }

  Widget _buildComparisonPlayRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isPlaying,
    required VoidCallback onPlay,
    required VoidCallback onStop,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.stop_circle_rounded
                  : Icons.play_circle_fill_rounded,
            ),
            color: color,
            iconSize: 32,
            onPressed: isPlaying ? onStop : onPlay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _getTooltipText(WordResult word) =>
      word.effectiveReviewKind?.label ??
      (word.verdict == WordVerdict.correct ? 'صحيحة' : 'مقبولة');

  Widget _buildActions(BuildContext context, RecitationProvider provider) {
    final retry =
        widget.onReplay ??
        (widget.resultOverride == null ? () => provider.retry(context) : null);
    final returnToSetup = widget.resultOverride == null
        ? provider.goToSetup
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (retry != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGold,
              foregroundColor: AppColors.darkBrown,
            ),
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة التسميع'),
          ),
        if (widget.onOpenHistory != null)
          OutlinedButton.icon(
            onPressed: widget.onOpenHistory,
            icon: const Icon(Icons.history_rounded),
            label: const Text('سجل التسميعات'),
          ),
        if (returnToSetup != null)
          OutlinedButton.icon(
            onPressed: returnToSetup,
            icon: const Icon(Icons.add_rounded),
            label: const Text('تسميع جديد'),
          ),
      ],
    );
  }
}
