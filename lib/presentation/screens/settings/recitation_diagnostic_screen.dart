import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/recitation_diagnostic_service.dart';
import '../../../core/constants/app_colors.dart';

class RecitationDiagnosticScreen extends StatefulWidget {
  const RecitationDiagnosticScreen({super.key});

  @override
  State<RecitationDiagnosticScreen> createState() =>
      _RecitationDiagnosticScreenState();
}

class _RecitationDiagnosticScreenState
    extends State<RecitationDiagnosticScreen> {
  final _service = RecitationDiagnosticService();

  DiagnosticReport? _report;
  bool _isRunning = false;
  String _currentCheck = '';

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _report = null;
      _currentCheck = 'جارٍ التهيئة...';
    });

    try {
      final report = await _service.runAll(
        onCheckStarted: (name) {
          if (mounted) setState(() => _currentCheck = 'جارٍ فحص: $name');
        },
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isRunning = false;
          _currentCheck = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentCheck = 'خطأ: $e';
        });
      }
    }
  }

  void _copyReport() {
    if (_report == null) return;
    Clipboard.setData(ClipboardData(text: _report!.toText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ التقرير', style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          '🔬 تشخيص نظام التسميع',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'نسخ التقرير',
              onPressed: _copyReport,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── زر التشغيل ───
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                icon: _isRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_circle_rounded, size: 22),
                label: Text(
                  _isRunning ? _currentCheck : 'تشغيل التشخيص الكامل',
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── النتائج ───
            if (_report != null) ...[
              // ملخص
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _report!.allPassed
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _report!.allPassed ? Colors.green : Colors.orange,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _report!.allPassed ? '✅' : '⚠️',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_report!.passedCount}/${_report!.checks.length} فحوصات اجتازت',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // قائمة الفحوصات
              Expanded(
                child: ListView.separated(
                  itemCount: _report!.checks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final check = _report!.checks[index];
                    return _CheckCard(check: check, isDark: isDark);
                  },
                ),
              ),

              const SizedBox(height: 12),
              // زر النسخ
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyReport,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('نسخ التقرير الكامل',
                      style: TextStyle(fontFamily: 'Tajawal')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (!_isRunning) ...[
              const Spacer(),
              const Icon(Icons.health_and_safety_rounded,
                  size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'اضغط الزر أعلاه لبدء فحص جميع مكونات التسميع',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.grey),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

/// بطاقة نتيجة فحص واحد
class _CheckCard extends StatelessWidget {
  final DiagnosticCheckResult check;
  final bool isDark;

  const _CheckCard({required this.check, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = check.passed ? Colors.green : Colors.red;
    final bgColor = check.passed
        ? Colors.green.withValues(alpha: 0.07)
        : Colors.red.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                check.passed ? '✅' : '❌',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          title: Text(
            check.name,
            style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          subtitle: check.duration != null
              ? Text(
                  '${check.duration!.inMilliseconds} ms',
                  style: const TextStyle(
                      fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey),
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // التفاصيل
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      check.detail,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),
                  // رسالة الخطأ
                  if (check.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              check.errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.red,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
