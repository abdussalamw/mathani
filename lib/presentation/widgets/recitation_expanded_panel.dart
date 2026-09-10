import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';

/// لوحة النتائج التفصيلية للتسميع — تظهر عند الضغط على ▲
class RecitationExpandedPanel extends StatelessWidget {
  const RecitationExpandedPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recProvider = context.watch<RecitationProvider>();
    final result = recProvider.currentResult;

    if (result == null) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 10) {
          context.read<UiProvider>().setShowRecitationResults(false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب المودرن
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // العنوان والتحكم
              Row(
                children: [
                  const SizedBox(width: 18),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'نتائج التسميع التفصيلية',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.expand_more_rounded, size: 24),
                    color: AppColors.mutedText,
                    onPressed: () => context.read<UiProvider>().setShowRecitationResults(false),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // المحتوى التفصيلي كبطاقات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // الدقة الكلية
                    _buildMetricCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      label: 'الدقة الكلية',
                      value: '${result.accuracyPercent}%',
                      sub: '${result.correctWords} كلمات صحيحة من ${result.totalWords}',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // السورة
                    _buildMetricCard(
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.blue,
                      label: 'السورة',
                      value: result.surahName,
                      sub: 'الآيات ${result.startAyah} - ${result.endAyah}',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // المدة
                    _buildMetricCard(
                      icon: Icons.timer_outlined,
                      iconColor: Colors.amber,
                      label: 'المدة',
                      value: _formatDuration(result.durationMs),
                      sub: null,
                      isDark: isDark,
                    ),
                    // أخطاء التجويد — التقييم الحالي محاكاة زائفة، نعرض الأخطاء فقط
                    if (recProvider.mistakesCount > 0) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildMetricCard(
                          icon: Icons.error_outline_rounded,
                          iconColor: Colors.red,
                          label: 'الأخطاء المكتشفة',
                          value: '${recProvider.mistakesCount}',
                          sub: 'كلمات لم تطابق نص المصحف',
                          isDark: isDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // الأزرار الأنيقة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<RecitationProvider>().goToHistory(),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('سجل التسميعات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<UiProvider>().setShowRecitationResults(false);
                          context.read<RecitationProvider>().reset();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5C16C), Color(0xFFCFB058)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.replay_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'إعادة التسميع',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? sub,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (sub != null) ...[
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}