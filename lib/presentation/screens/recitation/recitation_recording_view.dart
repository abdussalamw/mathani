import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/widgets/mushaf_page_widget.dart';
import 'package:mathani/data/services/glyph_data_loader.dart';
import 'package:mathani/data/models/page_glyph.dart';
import 'package:mathani/presentation/providers/mushaf_metadata_provider.dart';

/// شاشة التسجيل — المتابعة اللحظية على المصحف
class RecitationRecordingView extends StatefulWidget {
  const RecitationRecordingView({super.key});

  @override
  State<RecitationRecordingView> createState() =>
      _RecitationRecordingViewState();
}

class _RecitationRecordingViewState extends State<RecitationRecordingView>
    with TickerProviderStateMixin {
  Timer? _waveTimer;
  bool _readingAmplitude = false;
  late AnimationController _pulseController;

  // بيانات المصحف
  final GlyphDataLoader _glyphLoader = GlyphDataLoader();
  PageGlyph? _currentPageGlyph;
  bool _isLoadingPage = true;

  // مؤشر الصوت
  final List<double> _waveformData = List.generate(30, (_) => 0.1);
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCurrentPage();
      _startWaveform();
    });
  }

  Future<void> _loadCurrentPage() async {
    if (!mounted) return;
    final provider = context.read<RecitationProvider>();

    setState(() => _isLoadingPage = true);
    try {
      final glyph = await _glyphLoader.loadPage(provider.currentPage);
      if (mounted) {
        setState(() {
          _currentPageGlyph = glyph;
          _isLoadingPage = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recitation page: $e');
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  void _startWaveform() {
    final provider = context.read<RecitationProvider>();
    final sessionId = provider.activeSessionConfig?.sessionId;
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!mounted ||
          _readingAmplitude ||
          provider.state != RecitationState.recording ||
          provider.activeSessionConfig?.sessionId != sessionId) {
        return;
      }
      _readingAmplitude = true;
      try {
        final amplitude = await provider.getRecordingAmplitude();
        if (!mounted ||
            provider.state != RecitationState.recording ||
            provider.activeSessionConfig?.sessionId != sessionId) {
          return;
        }
        setState(() {
          _waveformData.removeAt(0);
          _waveformData.add(max(0.1, amplitude + _random.nextDouble() * 0.05));
        });
      } finally {
        _readingAmplitude = false;
      }
    });
  }

  Future<void> _togglePause() async {
    final provider = context.read<RecitationProvider>();
    if (provider.isPaused) {
      await provider.resumeRecording();
    } else {
      await provider.pauseRecording();
    }
  }

  Future<void> _stopRecording() async {
    _waveTimer?.cancel();
    await context.read<RecitationProvider>().stopRecording();
  }

  Future<void> _cancelRecording() async {
    _waveTimer?.cancel();
    await context.read<RecitationProvider>().cancelRecording();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecitationProvider>();
    final mushafMetadata = context.watch<MushafMetadataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // مراقبة تغيير الصفحة
    if (_currentPageGlyph?.page != provider.currentPage && !_isLoadingPage) {
      Future.microtask(() => _loadCurrentPage());
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // 1. خلفية المصحف الحقيقية
          if (_isLoadingPage || _currentPageGlyph == null)
            const Center(child: CircularProgressIndicator())
          else
            Opacity(
              opacity: 0.9,
              child: MushafPageWidget(
                page: _currentPageGlyph!,
                mushafId: mushafMetadata.currentMushafId,
                selectedSurah:
                    provider.matchedSurah, // تلوين الآية المكتشفة لحظياً
                selectedAyah: provider.matchedAyah,
                showInfo: true,
              ),
            ),

          // 2. غطاء علوي شفاف (شريط الحالة)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _cancelRecording,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تسميع حي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.5 + _pulseController.value * 0.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // 2.5. بطاقة التلقين العائمة (Prompt Word Overlay)
          if (provider.promptWord != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 230,
              left: 32,
              right: 32,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGold.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.brandGold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'الكلمة التالية: ',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        provider.promptWord!,
                        style: const TextStyle(
                          fontFamily: 'KFGQPC_HAFS',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. لوحة التحكم السفلية (Floating Control Panel)
          Positioned(
            bottom:
                MediaQuery.of(context).padding.bottom +
                20, // رفع اللوحة بناءً على منطقة الجهاز الآمنة
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[900]?.withValues(alpha: 0.98)
                    : Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الإحصائيات اللحظية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'آيات',
                        provider.matchedAyahsCount.toString(),
                        Icons.menu_book_rounded,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'أخطاء',
                        provider.mistakesCount.toString(),
                        Icons.error_outline_rounded,
                        Colors.red,
                      ),
                      _buildStatItem(
                        'مطابق',
                        '${((provider.overallConfidence).clamp(0.0, 1.0) * 100).round()}%',
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // الوقت + شدة الصوت
                  Row(
                    children: [
                      Text(
                        _formatDuration(provider.recordingDurationMs),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 25,
                          child: Row(
                            children: _waveformData
                                .map(
                                  (v) => Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      height: 4 + v * 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3 + v * 0.7,
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
                  const SizedBox(height: 12),
                  // النص المكتشف (Transcript)
                  if (provider.liveTranscript.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        provider.liveTranscript,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // أزرار التحكم
                  Row(
                    children: [
                      // زر الإيقاف المؤقت / الاستئناف
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _togglePause,
                          icon: Icon(
                            provider.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      // زر لقنّي
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            provider.triggerPrompt();
                          },
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            color: AppColors.brandGold,
                          ),
                          tooltip: 'لقّنّي',
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.stop_rounded, size: 20),
                          label: const Text(
                            'إنهاء وبدء التحليل',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}
