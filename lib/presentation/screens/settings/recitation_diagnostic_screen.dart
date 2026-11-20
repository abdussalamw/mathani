import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/recitation_diagnostic_service.dart';
import '../../providers/recitation_provider.dart';

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
  String? _failed;
  String _currentCheck = '';

  Future<void> _runDiagnostic() async {
    if (_isRunning) return;
    final provider = context.read<RecitationProvider>();
    setState(() {
      _isRunning = true;
      _report = null;
      _failed = null;
      _currentCheck = 'جارٍ بدء الفحص...';
    });

    try {
      final report = await _service.runAll(
        npuBackendConfigured: provider.isNpuSupported,
        whisperSelected: provider.engine == RecitationEngine.whisper,
        downloadingModel: provider.isZipformerDownloading,
        sessionActive: provider.activeSessionConfig != null,
        npuUnavailableReason: provider.npuUnavailableReason,
        lastVerifiedNpuAt: provider.lastVerifiedNpuAt,
        lastIssue: provider.lastDiagnosticIssue,
        onCheckStarted: (name) {
          if (mounted) setState(() => _currentCheck = 'جارٍ فحص $name...');
        },
      );
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = 'تعذّر إكمال الفحص. أعد المحاولة.');
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _copyReport() async {
    final report = _report;
    if (report == null) return;
    var message = 'تم نسخ تقرير التشخيص';
    try {
      await Clipboard.setData(ClipboardData(text: report.toText()));
    } catch (_) {
      message = 'تعذّر نسخ التقرير';
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final colors = Theme.of(context).colorScheme;
    final headingStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontFamily: 'Tajawal', fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تشخيص نظام التسميع',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'يعرض توافق الجهاز وملفات Zipformer وإذن الميكروفون '
            'ونتيجة آخر تحقق من NPU عند بدء التسميع.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isRunning ? null : _runDiagnostic,
            icon: _isRunning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.health_and_safety_outlined),
            label: Text(report == null ? 'تشغيل التشخيص' : 'إعادة الفحص'),
          ),
          if (_isRunning) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Text(_currentCheck)),
          ],
          if (_failed case final message?) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(message, style: TextStyle(color: colors.error)),
            ),
          ],
          if (report != null) ...[
            const SizedBox(height: 16),
            Card(
              color: report.firstBlocker == null
                  ? colors.surfaceContainerHighest
                  : colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.summary, style: headingStyle),
                      const SizedBox(height: 6),
                      Text(report.guidance),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final check in report.checks) _CheckCard(check: check),
          ],
        ],
      ),
      bottomNavigationBar: report == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('نسخ التقرير'),
              ),
            ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.check});

  final DiagnosticCheckResult check;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (check.status) {
      DiagnosticStatus.passed => (
        Icons.check_circle_outline,
        AppColors.success,
      ),
      DiagnosticStatus.blocked => (Icons.error_outline_rounded, colors.error),
      DiagnosticStatus.unverified => (
        Icons.pending_outlined,
        colors.onSurfaceVariant,
      ),
      DiagnosticStatus.info => (Icons.info_outline_rounded, colors.primary),
    };
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          check.name,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(check.status.label),
        initiallyExpanded: check.status == DiagnosticStatus.blocked,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(check.detail),
          if (check.action case final action?) ...[
            const SizedBox(height: 6),
            Text(action, style: TextStyle(color: colors.onSurfaceVariant)),
          ],
          if (check.name == RecitationDiagnosticStage.permission.label &&
              check.status == DiagnosticStatus.blocked)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: openAppSettings,
                child: const Text('فتح إعدادات الإذن'),
              ),
            ),
        ],
      ),
    );
  }
}
