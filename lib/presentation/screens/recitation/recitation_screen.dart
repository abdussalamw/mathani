import 'package:flutter/material.dart';
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
  const RecitationScreen({Key? key}) : super(key: key);

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
      case RecitationState.recording:
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
