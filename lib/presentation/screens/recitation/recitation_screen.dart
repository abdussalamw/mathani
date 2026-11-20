import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

import 'recitation_setup_view.dart';
import 'recitation_recording_view.dart';
import 'recitation_analysis_view.dart';
import 'recitation_result_view.dart';
import 'recitation_history_view.dart';
import 'recitation_analytics_view.dart';

/// الشاشة الرئيسية لقسم التسميع الذكي
/// تتحكم في التنقل بين الحالات المختلفة
class RecitationScreen extends StatelessWidget {
  const RecitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecitationProvider>(
      builder: (context, provider, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentView(provider),
        );
      },
    );
  }

  Widget _buildCurrentView(RecitationProvider provider) {
    switch (provider.state) {
      case RecitationState.idle:
      case RecitationState.setup:
        return const RecitationSetupView(key: ValueKey('setup'));
      case RecitationState.preparing:
        return Center(
          key: const ValueKey('preparing'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(provider.analysisStep),
              const SizedBox(height: 12),
              TextButton(
                onPressed: provider.cancelRecording,
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      case RecitationState.recording:
      case RecitationState.paused:
        return const RecitationRecordingView(key: ValueKey('recording'));
      case RecitationState.analyzing:
        return const RecitationAnalysisView(key: ValueKey('analyzing'));
      case RecitationState.result:
        return const RecitationResultView(key: ValueKey('result'));
      case RecitationState.history:
        return const RecitationHistoryView(key: ValueKey('history'));
      case RecitationState.analytics:
        return const RecitationAnalyticsView(key: ValueKey('analytics'));
      case RecitationState.error:
        return const RecitationSetupView(key: ValueKey('setup'));
    }
  }
}
