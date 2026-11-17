import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/review_summary.dart';

class ReviewSummaryCard extends StatelessWidget {
  final ReviewSummary summary;
  final Future<void> Function()? onReview;
  const ReviewSummaryCard({super.key, required this.summary, this.onReview});

  @override
  Widget build(BuildContext context) {
    final target = summary.suggestedReview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مراجعتك خلال آخر سبعة أيام',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('${summary.sessions} جلسات'),
                Text('${summary.activeDays} أيام نشطة'),
                Text('${(summary.durationSeconds / 60).floor()} دقيقة'),
                Text('متوسط الدقة ${summary.averageAccuracy}٪'),
              ],
            ),
            if (summary.accuracyChange != null) ...[
              const SizedBox(height: 8),
              Text(
                'التغير عن الأيام السبعة السابقة: ${summary.accuracyChange! > 0 ? '+' : ''}${summary.accuracyChange} نقطة',
              ),
            ],
            if (target != null) ...[
              const Divider(height: 24),
              Text(
                'المراجعة المقترحة: سورة ${target.surahName}، الآيات ${target.startAyah}–${target.endAyah}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppColors.brandGold,
                ),
              ),
              Text(
                'دقة آخر جلسة ${target.accuracyPercent}٪؛ يُفضّل إعادة مراجعة هذا المقطع.',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('إعداد هذه المراجعة'),
              ),
            ] else if (summary.sessions > 0) ...[
              const SizedBox(height: 8),
              const Text('واصل المراجعة المنتظمة لتثبيت الحفظ.'),
            ],
          ],
        ),
      ),
    );
  }
}
