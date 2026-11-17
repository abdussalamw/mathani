import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:intl/intl.dart';

/// شاشة سجل التسميعات السابقة
class RecitationHistoryView extends StatelessWidget {
  const RecitationHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();

    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: SafeArea(
        child: Column(
          children: [
            // ─── شريط علوي ───
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
                      'سجل التسميعات',
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

            // ─── القائمة ───
            Expanded(
              child: provider.sessions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = provider.sessions[index];
                        return GestureDetector(
                          onTap: () => provider.selectSession(session),
                          child: _buildSessionCard(session, isDark),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد تسميعات سابقة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ابدأ تسميعك الأول من الشاشة الرئيسية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(dynamic session, bool isDark) {
    Color gradeColor;
    if (session.accuracyPercent >= 85) {
      gradeColor = AppColors.success;
    } else if (session.accuracyPercent >= 60) {
      gradeColor = AppColors.warning;
    } else {
      gradeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // النسبة
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${session.accuracyPercent}%',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سورة ${session.surahName}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'آية ${session.startAyah} - ${session.endAyah} • ${session.correctWords}/${session.totalWords} كلمة',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          // التاريخ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MM/dd').format(session.createdAt),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session.overallGrade,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
