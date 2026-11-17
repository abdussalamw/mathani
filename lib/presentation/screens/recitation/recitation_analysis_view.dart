import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

/// شاشة التحليل — مؤشر تقدم متحرك مع خطوات التحليل
class RecitationAnalysisView extends StatelessWidget {
  const RecitationAnalysisView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();

    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // ─── أيقونة NPU متحركة ───
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (_, value, child) => Transform.scale(
                scale: 0.8 + value * 0.2,
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandGold.withValues(alpha: 0.15),
                      AppColors.brandGold.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  size: 56,
                  color: AppColors.brandGold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ─── النص ───
            const Text(
              'جارٍ التحليل بالذكاء الاصطناعي',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slateText,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                provider.analysisStep,
                key: ValueKey(provider.analysisStep),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ─── شريط التقدم ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: provider.analysisProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.brandGold.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.brandGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(provider.analysisProgress * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ─── النص المتدفق (الكلمات الحية) ───
            if (provider.liveTranscript.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.brandGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    provider.liveTranscript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'QCF4_BSML', // أو Tajawal
                      fontSize: 22,
                      height: 1.8,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],

            // ─── خطوات التحليل ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildStep(
                    'التعرف على التلاوة',
                    Icons.hearing_rounded,
                    provider.analysisProgress >= 0.1,
                    provider.analysisProgress >= 0.4,
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    'تحديد الآيات',
                    Icons.find_in_page_rounded,
                    provider.analysisProgress >= 0.5,
                    provider.analysisProgress >= 0.7,
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    'تقييم التجويد',
                    Icons.auto_awesome_rounded,
                    provider.analysisProgress >= 0.8,
                    provider.analysisProgress >= 1.0,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String label, IconData icon, bool isActive, bool isDone) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : (isActive
                      ? AppColors.brandGold
                      : Colors.grey.withValues(alpha: 0.2)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: isActive || isDone
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isDone
                  ? AppColors.success
                  : (isActive ? AppColors.slateText : AppColors.mutedText),
            ),
          ),
        ),
        if (isActive && !isDone)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.brandGold),
            ),
          ),
      ],
    );
  }
}
