import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

import '../../widgets/review_summary_card.dart';

/// شاشة لوحة تحليلات وإحصاءات التسميع المتقدمة (لوحة تحكم الحافظ)
class RecitationAnalyticsView extends StatelessWidget {
  const RecitationAnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();
    final summary = provider.reviewSummary;

    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: SafeArea(
        child: Column(
          children: [
            // ─── شريط العنوان ───
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
                      'لوحة تحكم الحافظ',
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

            // ─── المحتوى التحليلي ───
            Expanded(
              child: provider.allSessions.isEmpty
                  ? _buildEmptyState(isDark)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReviewSummaryCard(
                            summary: summary,
                            onReview: summary.suggestedReview == null
                                ? null
                                : () async {
                                    final prepared = await provider
                                        .prepareSuggestedReview(
                                          summary.suggestedReview!,
                                        );
                                    if (!context.mounted || prepared) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'تعذّر إعداد المراجعة، يرجى إعادة المحاولة',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          // 1. شعلة الاستمرارية (Streak) + نسبة الحفظ الكلية
                          Row(
                            children: [
                              Expanded(
                                child: _buildStreakCard(
                                  provider.currentStreak,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildProgressCard(
                                  provider.memorizationProgress,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. بطاقة الإحصائيات التراكمية
                          _buildCumulativeStatsCard(provider, isDark),
                          const SizedBox(height: 16),

                          // 3. مكامن الخطأ (السور التي تحتاج مراجعة)
                          _buildHotspotsCard(provider.hotspotSurahs, isDark),
                          const SizedBox(height: 100), // مساحة للتنقل
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 72,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد تحليلات كافية بعد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.slateText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'قم بإتمام جلسات التسميع ليقوم الذكاء الاصطناعي بحساب استمراريتك ومكامن خطئك وإظهارها هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // أيقونة شعلة متحركة أو ملونة
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.orange, Colors.red],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$streak',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slateText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'أيام متتالية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, bool isDark) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: AppColors.brandGold.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandGold),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تقدم الحفظ الكلي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'سور تم تسميعها بنجاح',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeStatsCard(RecitationProvider provider, bool isDark) {
    final avgAccuracy = provider.averageAccuracy;
    final totalWords = provider.totalWordsRead;
    final totalDurationMin = (provider.totalDurationSeconds / 60).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصاءات الحفظ التراكمية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatDetailItem(
                'متوسط الدقة',
                '$avgAccuracy%',
                Icons.check_circle_outline_rounded,
                AppColors.success,
              ),
              _buildStatDetailItem(
                'إجمالي الكلمات',
                '$totalWords',
                Icons.menu_book_rounded,
                Colors.blue,
              ),
              _buildStatDetailItem(
                'وقت التسميع',
                '$totalDurationMin دقيقة',
                Icons.timer_outlined,
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.slateText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildHotspotsCard(List<Map<String, dynamic>> hotspots, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مكامن الأخطاء (سور تحتاج مراجعة)',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'السور الأقل دقة بناءً على جلساتك الأخيرة لتركز عليها:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          if (hotspots.isEmpty)
            const Text(
              'لا توجد بيانات كافية.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hotspots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = hotspots[index];
                final acc = item['accuracy'] as int;
                Color statusColor = Colors.red;
                if (acc >= 80) {
                  statusColor = AppColors.success;
                } else if (acc >= 60) {
                  statusColor = AppColors.warning;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF151412)
                        : AppColors.brandBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$acc%',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'سورة ${item['name']}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateText,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
