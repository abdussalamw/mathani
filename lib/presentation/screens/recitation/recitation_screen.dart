import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

import 'recitation_setup_view.dart';
import 'recitation_recording_view.dart';
import 'recitation_analysis_view.dart';
import 'recitation_result_view.dart';
import 'recitation_history_view.dart';
import 'recitation_analytics_view.dart';
import 'recitation_error_review_view.dart';

enum RecitationTab { practice, history, review }

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key, this.initialTab = RecitationTab.practice});

  final RecitationTab initialTab;

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen>
    with SingleTickerProviderStateMixin {
  late RecitationTab _tab;
  late final TabController _tabs;
  late final Set<RecitationTab> _visitedTabs;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RecitationProvider>();
    _tab =
        widget.initialTab == RecitationTab.practice &&
            provider.state == RecitationState.history
        ? RecitationTab.history
        : widget.initialTab;
    _visitedTabs = {_tab};
    _tabs = TabController(
      length: RecitationTab.values.length,
      initialIndex: _tab.index,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecitationProvider>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _buildSessionView(provider) ?? _buildTabs(provider),
      ),
    );
  }

  Widget _buildTabs(RecitationProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      key: const ValueKey('recitation-tabs'),
      bottom: false,
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            indicatorColor: AppColors.brandGold,
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
            ),
            onTap: (index) {
              final tab = RecitationTab.values[index];
              if (_tab == tab) return;
              if (provider.state == RecitationState.result ||
                  provider.state == RecitationState.history) {
                provider.goToSetup();
              }
              setState(() {
                _tab = tab;
                _visitedTabs.add(tab);
              });
            },
            tabs: const [
              Tab(text: 'التسميع'),
              Tab(text: 'السجل'),
              Tab(text: 'مراجعة الأخطاء'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              children: [
                for (final tab in RecitationTab.values)
                  if (_visitedTabs.contains(tab))
                    switch (tab) {
                      RecitationTab.practice => const RecitationSetupView(),
                      RecitationTab.history => RecitationHistoryView(
                        onOpenResult: _openSavedResult,
                      ),
                      RecitationTab.review => RecitationErrorReviewView(
                        onOpenResult: (result, word) =>
                            _openSavedResult(result, focusedWord: word),
                      ),
                    }
                  else
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSavedResult(RecitationResult result, {WordResult? focusedWord}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: RecitationResultView(
            resultOverride: result,
            focusedWord: focusedWord,
          ),
        ),
      ),
    );
  }

  Widget? _buildSessionView(RecitationProvider provider) {
    switch (provider.state) {
      case RecitationState.idle:
      case RecitationState.setup:
      case RecitationState.history:
      case RecitationState.error:
        return null;
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
        return _tab == RecitationTab.practice
            ? const RecitationResultView(key: ValueKey('result'))
            : null;
      case RecitationState.analytics:
        return _tab == RecitationTab.practice
            ? const RecitationAnalyticsView(key: ValueKey('analytics'))
            : null;
    }
  }
}
