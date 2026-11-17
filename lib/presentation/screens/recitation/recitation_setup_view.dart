import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mathani/core/constants/app_colors.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';

/// شاشة إعداد التسميع — مع نظام حماية المتطلبات (NPU, Models, Mic)
class RecitationSetupView extends StatefulWidget {
  const RecitationSetupView({Key? key}) : super(key: key);

  @override
  State<RecitationSetupView> createState() => _RecitationSetupViewState();
}

class _RecitationSetupViewState extends State<RecitationSetupView> {
  @override
  void initState() {
    super.initState();
    // التحقق من الصلاحيات والجاهزية عند الفتح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecitationProvider>().checkMicrophonePermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<RecitationProvider>();

    // ─── الحماية 1: التحقق من إمكانية تشغيل محرك التعرف الصوتي (CPU) ───
    if (!provider.isNpuSupported) {
      return _buildNotSupportedView(isDark);
    }

    return Container(
      color: isDark ? const Color(0xFF131315) : AppColors.brandBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ─── الترويسة ───
              _buildHeader(isDark),
              const SizedBox(height: 28),

              // ─── اختيار الوضع ───
              _buildModeSelector(context, provider, isDark),
              const SizedBox(height: 24),

              // ─── اختيار السورة (في الوضع المحدد) ───
              if (provider.mode == RecitationMode.selected) ...[
                _buildSurahSelector(context, provider, isDark),
                const SizedBox(height: 16),

                // ─── نطاق الآيات ───
                if (provider.selectedSurah != null)
                  _buildAyahRangeSelector(provider, isDark),
                const SizedBox(height: 24),
              ],

              // ─── عرض الأخطاء إن وجدت ───
              if (provider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
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
                          provider.errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── زر البدء (مع التحقق من النماذج والصلاحيات) ───
              _buildStartButton(context, provider),
              const SizedBox(height: 16),

              // ─── زر السجل ───
              _buildHistoryButton(context, provider, isDark),
              const SizedBox(height: 20),

              // ─── بطاقة حالة النظام ───
              _buildSystemStatusCard(provider, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotSupportedView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory_rounded,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'المعالج غير مدعوم',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slateText,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ميزة التسميع الذكي تتطلب جهازاً يحتوي على معالج ذكاء اصطناعي (NPU) لضمان دقة وسرعة التحليل اللحظي دون إنترنت.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
            Icons.mic_none_rounded,
            size: 48,
            color: AppColors.brandGold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'التسميع الذكي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.slateText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'اقرأ وسيتعرف النظام على تلاوتك ويقوم بمتابعتك على المصحف لحظياً',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    RecitationProvider provider,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 4, bottom: 10),
          child: Text(
            'وضع التسميع',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                icon: Icons.auto_awesome,
                title: 'وضع حر',
                subtitle: 'ابدأ من أي مكان',
                isSelected: provider.mode == RecitationMode.free,
                onTap: () => provider.setMode(RecitationMode.free),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                icon: Icons.checklist_rounded,
                title: 'وضع محدد',
                subtitle: 'اختر سورة وآيات',
                isSelected: provider.mode == RecitationMode.selected,
                onTap: () => provider.setMode(RecitationMode.selected),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandGold.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1E1E22) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.brandGold
                : Colors.grey.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.brandGold : AppColors.mutedText,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.brandGold : AppColors.slateText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahSelector(
    BuildContext context,
    RecitationProvider provider,
    bool isDark,
  ) {
    final surahs = context.read<QuranProvider>().surahs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            'اختر السورة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
        ),
        InkWell(
          onTap: () => _showSurahPicker(context, provider, surahs),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.brandGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.selectedSurah != null
                        ? 'سورة ${provider.selectedSurahName}'
                        : 'اضغط لاختيار السورة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: provider.selectedSurah != null
                          ? AppColors.slateText
                          : AppColors.mutedText,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAyahRangeSelector(RecitationProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نطاق الآيات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'من',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.startAyah}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'إلى',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.endAyah}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(
              provider.startAyah.toDouble(),
              provider.endAyah.toDouble(),
            ),
            min: 1,
            max: provider.totalAyahs.toDouble(),
            divisions: provider.totalAyahs - 1 > 0
                ? provider.totalAyahs - 1
                : 1,
            activeColor: AppColors.brandGold,
            inactiveColor: AppColors.brandGold.withValues(alpha: 0.15),
            onChanged: (values) =>
                provider.setAyahRange(values.start.round(), values.end.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, RecitationProvider provider) {
    String label = 'ابدأ التسميع';
    IconData icon = Icons.mic_rounded;
    Color buttonColor = AppColors.primary;
    VoidCallback? action;

    if (!provider.isAsrModelDownloaded) {
      if (provider.isAsrDownloading) {
        label =
            'جارِ التحميل... ${(provider.asrDownloadProgress * 100).toInt()}%';
        icon = Icons.downloading_rounded;
        buttonColor = AppColors.brandGold.withValues(alpha: 0.7);
        action = null; // تعطيل الزر أثناء التحميل
      } else {
        label = 'تحميل النماذج للبدء';
        icon = Icons.download_rounded;
        buttonColor = AppColors.brandGold;
        action = () async {
          await provider.downloadAsrModel();
          provider.checkModelsState();
        };
      }
    } else if (!provider.hasMicrophonePermission) {
      label = 'منح صلاحية الميكروفون';
      icon = Icons.security_rounded;
      buttonColor = Colors.orange;
      action = () => provider.checkMicrophonePermission();
    } else {
      final bool canStart =
          provider.mode == RecitationMode.free ||
          (provider.mode == RecitationMode.selected &&
              provider.selectedSurah != null);

      if (canStart) {
        action = () => provider.goToRecording(context);
      } else {
        buttonColor = AppColors.mutedText.withValues(alpha: 0.3);
      }

      // تسجيل الحالة للتشخيص
      if (action == null) {
        debugPrint(
          '🚫 زر البدء معطل: mode=${provider.mode}, surah=${provider.selectedSurah}',
        );
      }
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: (action != null && !provider.isInitializingRecording)
            ? [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: provider.isInitializingRecording ? null : action,
          child: Center(
            child: provider.isInitializingRecording
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(
    BuildContext context,
    RecitationProvider provider,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => provider.goToHistory(),
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text(
              'سجل التسميعات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGold,
              side: BorderSide(
                color: AppColors.brandGold.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => provider.goToAnalytics(),
            icon: const Icon(Icons.analytics_rounded, size: 16),
            label: const Text(
              'لوحة التحليلات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGold,
              side: BorderSide(
                color: AppColors.brandGold.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // زر معاينة تقرير تجريبي
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => provider.loadDemoResult(),
            icon: const Icon(
              Icons.preview_rounded,
              size: 18,
              color: AppColors.brandGold,
            ),
            label: const Text(
              'معاينة شكل تقرير التسميع وتلوين الكلمات (Demo)',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: AppColors.brandGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusCard(RecitationProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: provider.isAsrModelDownloaded
            ? AppColors.success.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.isAsrModelDownloaded
              ? AppColors.success.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.isAsrModelDownloaded
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: provider.isAsrModelDownloaded
                ? AppColors.success
                : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.isAsrModelDownloaded
                  ? 'جميع المتطلبات جاهزة (بالـ NPU)'
                  : 'النماذج الصوتية مفقودة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: provider.isAsrModelDownloaded
                    ? AppColors.success
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSurahPicker(
    BuildContext context,
    RecitationProvider provider,
    List surahs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E22)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختر السورة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateText,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    final isSelected = provider.selectedSurah == surah.number;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.brandGold.withValues(
                        alpha: 0.08,
                      ),
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandGold.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${surah.number}',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.brandGold
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameArabic,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.brandGold
                              : AppColors.slateText,
                        ),
                      ),
                      subtitle: Text(
                        '${surah.numberOfAyahs} آية',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.brandGold,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        provider.selectSurah(
                          surah.number,
                          surah.nameArabic,
                          surah.numberOfAyahs,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
