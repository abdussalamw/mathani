import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/data/models/recitation_result.dart';

/// شاشة النتائج — تلوين كلمة بكلمة مع إحصائيات
class RecitationResultView extends StatelessWidget {
  const RecitationResultView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();
    final result = provider.currentResult;

    if (result == null) {
      return const Center(child: Text('لا توجد نتائج'));
    }

    return Container(
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.slateText,
                    ),
                    onPressed: () => provider.goToSetup(),
                  ),
                  const Expanded(
                    child: Text(
                      'نتيجة التسميع',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ─── المحتوى ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ─── بطاقة النتيجة الرئيسية ───
                    _buildScoreCard(result, isDark),
                    const SizedBox(height: 16),

                    // ─── إحصائيات سريعة ───
                    _buildQuickStats(result, isDark),
                    const SizedBox(height: 20),

                    // ─── الآيات كلمة بكلمة ───
                    _buildWordByWordSection(context, result, isDark),
                    const SizedBox(height: 20),

                    // ─── أزرار الإجراءات ───
                    _buildActions(context, provider),
                    const SizedBox(height: 100), // مساحة للشريط السفلي
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(RecitationResult result, bool isDark) {
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
            'سورة ${result.surahName} — آية ${result.startAyah} إلى ${result.endAyah}',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(RecitationResult result, bool isDark) {
    return Row(
      children: [
        _buildStatChip(
          '${result.correctWords}',
          'صحيح',
          AppColors.success,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '${result.acceptableWords}',
          'مقبول',
          AppColors.warning,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildStatChip('${result.incorrectWords}', 'خطأ', Colors.red, isDark),
        const SizedBox(width: 8),
        _buildStatChip(
          '${result.skippedWords}',
          'متجاوز',
          AppColors.mutedText,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatChip(String count, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordByWordSection(
    BuildContext context,
    RecitationResult result,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 4, bottom: 12),
          child: Text(
            'التفصيل آية بآية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
        ),
        ...result.wordsByAyah.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رقم الآية
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'الآية ${entry.key}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // الكلمات
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: entry.value.map((word) {
                      return _buildWordChip(context, word, result);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWordChip(
    BuildContext context,
    WordResult word,
    RecitationResult result,
  ) {
    Color chipColor;
    Color textColor;

    switch (word.verdict) {
      case WordVerdict.correct:
        chipColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        break;
      case WordVerdict.acceptable:
        chipColor = AppColors.warning.withValues(alpha: 0.12);
        textColor = const Color(0xFFE65100); // برتقالي غامق
        break;
      case WordVerdict.incorrect:
        chipColor = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.red;
        break;
      case WordVerdict.skipped:
        chipColor = Colors.grey.withValues(alpha: 0.1);
        textColor = AppColors.mutedText;
        break;
    }

    return GestureDetector(
      onTap: () {
        _showComparisonDialog(context, word, result);
      },
      child: Tooltip(
        message: _getTooltipText(word),
        preferBelow: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: textColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            word.expectedWord,
            style: TextStyle(
              fontFamily: 'KFGQPC_HAFS',
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showComparisonDialog(
    BuildContext context,
    WordResult word,
    RecitationResult result,
  ) {
    final provider = context.read<RecitationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    color: AppColors.brandGold,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'مقارنة تلاوة الكلمة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // رسم الكلمة عثمانياً
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandGold.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          word.expectedWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'KFGQPC_HAFS',
                            fontSize: 36,
                            color: AppColors.brandGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نطقك المكتشف: "${word.spokenWord.isNotEmpty ? word.spokenWord : 'لا يوجد'}"',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // تشغيل تسجيل المستخدم
                  if (result.audioPath != null &&
                      word.startTimeMs != null &&
                      word.endTimeMs != null &&
                      word.endTimeMs! > word.startTimeMs!) ...[
                    _buildComparisonPlayRow(
                      context: context,
                      label: 'صوتك المسجل لهذه الكلمة',
                      icon: Icons.mic_rounded,
                      color: AppColors.primary,
                      isPlaying: false,
                      onPlay: () {
                        provider.playUserWordAudio(result.audioPath!, word);
                      },
                      onStop: () {
                        provider.stopUserAudio();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // تشغيل تلاوة الشيخ المنشاوي
                  AnimatedBuilder(
                    animation: provider,
                    builder: (context, _) {
                      return _buildComparisonPlayRow(
                        context: context,
                        label: 'تلاوة الشيخ (المنشاوي)',
                        icon: Icons.record_voice_over_rounded,
                        color: Colors.amber,
                        isPlaying: provider.isSheikhPlaying,
                        onPlay: () {
                          provider.playSheikhAyah(
                            word.surahNumber,
                            word.ayahNumber,
                          );
                        },
                        onStop: () {
                          provider.stopSheikhAudio();
                        },
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    provider.stopUserAudio();
                    provider.stopSheikhAudio();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      provider.stopUserAudio();
      provider.stopSheikhAudio();
    });
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

  String _getTooltipText(WordResult word) {
    final verdictText = {
      WordVerdict.correct: '✅ صحيح',
      WordVerdict.acceptable: '⚠️ مقبول',
      WordVerdict.incorrect: '❌ خطأ',
      WordVerdict.skipped: '⏭ لم تُقرأ',
    }[word.verdict]!;

    return '$verdictText (${(word.confidence * 100).round()}%)';
  }

  Widget _buildActions(BuildContext context, RecitationProvider provider) {
    return Column(
      children: [
        // إعادة التسميع
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => provider.retry(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'إعادة التسميع',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // تسميع جديد
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => provider.goToSetup(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'تسميع جديد',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGold,
              side: BorderSide(
                color: AppColors.brandGold.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
