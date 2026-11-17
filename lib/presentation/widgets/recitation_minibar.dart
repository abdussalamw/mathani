import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/providers/ui_provider.dart';
import 'package:mathani/data/services/audio_recorder_service.dart';

/// شريط التسميع الذكي الصغير — يظهر فوق BottomNavigationBar
class RecitationMiniBar extends StatefulWidget {
  const RecitationMiniBar({Key? key}) : super(key: key);

  @override
  State<RecitationMiniBar> createState() => _RecitationMiniBarState();
}

class _RecitationMiniBarState extends State<RecitationMiniBar>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _waveTimer;
  int _elapsedMs = 0;
  late AnimationController _pulseController;
  final List<double> _waveformData = List.generate(20, (_) => 0.1);
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimers() {
    _timer?.cancel();
    _waveTimer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs += 100);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!mounted) return;
      final provider = context.read<RecitationProvider>();
      if (provider.isPaused) {
        setState(() {
          _waveformData.removeAt(0);
          _waveformData.add(0.05);
        });
        return;
      }
      final amp = await AudioRecorderService().getAmplitude();
      if (mounted) {
        setState(() {
          _waveformData.removeAt(0);
          _waveformData.add(max(0.1, amp + (_random.nextDouble() * 0.05)));
        });
      }
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _waveTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recProvider = context.watch<RecitationProvider>();
    final uiProvider = context.watch<UiProvider>();
    final isRecording = uiProvider.isRecitationActive;

    // تحميل النموذج جارٍ
    if (recProvider.isModelLoading) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'جارٍ تحضير نموذج الذكاء الاصطناعي...',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
              onPressed: () {
                uiProvider.hideRecitationMinibar();
                recProvider.reset();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // جاري التحليل النهائي
    if (recProvider.state == RecitationState.analyzing) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recProvider.analysisStep.isNotEmpty
                    ? recProvider.analysisStep
                    : 'جاري تحليل نطق الآيات...',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // حالة الخطأ
    if (recProvider.state == RecitationState.error ||
        recProvider.errorMessage != null) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recProvider.errorMessage ?? 'حدث خطأ غير متوقع',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
              onPressed: () {
                uiProvider.hideRecitationMinibar();
                recProvider.reset();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // ─── وضع النتائج بعد التوقف ───
    if (recProvider.currentResult != null) {
      final result = recProvider.currentResult!;
      final isExcellent = result.accuracyPercent >= 80;
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة النتيجة العصرية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isExcellent
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExcellent
                      ? AppColors.success.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExcellent
                        ? Icons.stars_rounded
                        : Icons.info_outline_rounded,
                    color: isExcellent ? AppColors.success : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${result.accuracyPercent}%',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isExcellent ? AppColors.success : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${result.correctWords}/${result.totalWords} كلمة)',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // زر توسيع النتائج بالهوية الذهبية للتطبيق
            GestureDetector(
              onTap: () {
                uiProvider.setShowRecitationResults(true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5C16C), Color(0xFFCFB058)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'توسيع النتائج',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.expand_less, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // زر إغلاق الجلسة
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
              onPressed: () {
                uiProvider.hideRecitationMinibar();
                recProvider.reset();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // ─── وضع التسجيل ───
    return GestureDetector(
      onTap: isRecording ? null : _startRecitation,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151412) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // زر الميكروفون المودرن مع توهج نبضي
                GestureDetector(
                  onTap: isRecording ? _stopRecitation : null,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: isRecording
                            ? LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFE5C16C), Color(0xFFCFB058)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isRecording
                                ? Colors.red.withValues(
                                    alpha:
                                        0.4 *
                                        (0.5 + _pulseController.value * 0.5),
                                  )
                                : AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: isRecording
                                ? 12 + _pulseController.value * 6
                                : 10,
                            spreadRadius: isRecording
                                ? _pulseController.value * 2
                                : 0,
                            offset: isRecording
                                ? Offset.zero
                                : const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // العدادات ببطاقات كبسولية أنيقة
                if (isRecording) ...[
                  _buildBadge(
                    'آيات',
                    '${recProvider.matchedAyahsCount}',
                    Icons.menu_book_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    'أخطاء',
                    '${recProvider.mistakesCount}',
                    Icons.error_outline_rounded,
                    Colors.red,
                  ),
                ],
                const Spacer(),
                // وقت التسجيل والتوقيف المؤقت
                if (isRecording) ...[
                  GestureDetector(
                    onTap: () {
                      final p = context.read<RecitationProvider>();
                      if (p.isPaused) {
                        p.resumeRecording();
                        _startTimers();
                      } else {
                        p.pauseRecording();
                        _stopTimers();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        recProvider.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // زر لقني في المينيبار
                  GestureDetector(
                    onTap: () {
                      recProvider.triggerPrompt();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.brandGold,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(_elapsedMs),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // زر إلغاء التسجيل بالكامل
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      _stopTimers();
                      recProvider.cancelRecording();
                      uiProvider.hideRecitationMinibar();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
                if (!isRecording) ...[
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'اضغط لبدء التسميع الذكي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (recProvider.sessions.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          _buildHistoryBadge(context, recProvider),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                    onPressed: () {
                      uiProvider.hideRecitationMinibar();
                      recProvider.reset();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            // بطاقة التلقين في المينيبار
            if (isRecording && recProvider.promptWord != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.brandGold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'الكلمة التالية: ',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                    Text(
                      recProvider.promptWord!,
                      style: const TextStyle(
                        fontFamily: 'KFGQPC_HAFS',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // موجات صوتية أنيقة بكبسولات ملونة
            if (isRecording) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: _waveformData
                            .map(
                              (v) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  height: 2 + v * 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        AppColors.primary,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // النص المكتشف بشكل رائع ومميز
            if (isRecording && recProvider.liveTranscript.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recProvider.liveTranscript,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBadge(
    BuildContext context,
    RecitationProvider recProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showPreviousRecitationsSheet(context, recProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.brandGold.withValues(alpha: 0.12)
              : AppColors.brandGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brandGold.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              color: AppColors.brandGold,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'التسميعات السابقة (${recProvider.sessions.length})',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: AppColors.brandGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviousRecitationsSheet(
    BuildContext context,
    RecitationProvider recProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uiProvider = context.read<UiProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151412) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.brandGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'التسميعات الأخيرة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slateText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recProvider.sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = recProvider.sessions[index];
                  final isExcellent = session.accuracyPercent >= 80;
                  final badgeColor = isExcellent
                      ? AppColors.success
                      : Colors.orange;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      recProvider.selectSession(session);
                      uiProvider.setShowRecitationResults(true);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E22)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandGold.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.brandGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سورة ${session.surahName}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slateText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الآيات ${session.startAyah} - ${session.endAyah} • ${DateFormat('yyyy/MM/dd hh:mm a').format(session.createdAt)}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 10,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${session.accuracyPercent}%',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startRecitation() async {
    final uiProvider = context.read<UiProvider>();
    final recProvider = context.read<RecitationProvider>();
    uiProvider.openRecitationMinibar();
    uiProvider.setRecitationActive(true);
    await recProvider.startRecitationFromMinibar();
    if (recProvider.isRecording) {
      _startTimers();
    }
  }

  void _stopRecitation() {
    _stopTimers();
    final recProvider = context.read<RecitationProvider>();
    recProvider.stopRecording();
    context.read<UiProvider>().setRecitationActive(false);
    context.read<UiProvider>().setShowRecitationResults(false);
  }
}
