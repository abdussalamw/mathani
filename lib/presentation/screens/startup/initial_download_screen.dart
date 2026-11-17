import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/local_tafsir_service.dart';
import '../../providers/mushaf_metadata_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/main_shell_screen.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/app_localizations.dart';

class InitialDownloadScreen extends StatefulWidget {
  const InitialDownloadScreen({super.key});

  @override
  State<InitialDownloadScreen> createState() => _InitialDownloadScreenState();
}

class _InitialDownloadScreenState extends State<InitialDownloadScreen> {
  String? _selectedMushafId;
  bool _isDownloading = false;
  double _mushafProgress = 0.0;
  double _tafsirProgress = 0.0;
  String _statusMessage = '';
  bool _hasError = false;
  MushafMetadataProvider? _downloadProvider;
  bool _wakelockEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MushafMetadataProvider>();
      if (provider.availableMushafs.isNotEmpty) {
        setState(() {
          _selectedMushafId = provider.availableMushafs
              .firstWhere(
                (m) => m.identifier == 'qcf2_v4_woff2',
                orElse: () => provider.availableMushafs.first,
              )
              .identifier;
        });
      }
    });
  }

  @override
  void dispose() {
    _downloadProvider?.removeListener(_onProviderChange);
    unawaited(_releaseWakelock());
    super.dispose();
  }

  Future<void> _releaseWakelock() async {
    if (!_wakelockEnabled) return;
    _wakelockEnabled = false;
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock release failed: $e');
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  Future<void> _startDownload() async {
    final mushafId = _selectedMushafId;
    if (mushafId == null || _isDownloading) return;

    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<MushafMetadataProvider>();

    setState(() {
      _isDownloading = true;
      _hasError = false;
      _statusMessage = l10n.initDownloading;
      _mushafProgress = 0.0;
      _tafsirProgress = 0.0;
    });

    try {
      await WakelockPlus.enable();
      _wakelockEnabled = true;
      if (!mounted) return;

      // 1. تعيين المصحف الافتراضي
      await provider.setMushaf(mushafId);
      if (!mounted) return;

      // 2. تحميل المصحف المختار
      setState(() {
        _statusMessage = l10n.initDownloading;
      });

      // نستمع لمؤشر تقدم تحميل المصحف من المزود
      _downloadProvider = provider;
      provider.addListener(_onProviderChange);
      try {
        await provider.downloadMushaf(mushafId);
      } finally {
        provider.removeListener(_onProviderChange);
        _downloadProvider = null;
      }
      if (!mounted) return;
      if (!provider.availableMushafs.any(
        (m) => m.identifier == mushafId && m.isDownloaded,
      )) {
        throw Exception(l10n.errorUnknown);
      }
      setState(() => _mushafProgress = 1.0);

      // 3. تحميل التفسير الميسر
      setState(() {
        _statusMessage = l10n.initTafsir;
      });

      await LocalTafsirService.instance.downloadAndExtractTafsir(
        onProgress: (p) {
          if (mounted) setState(() => _tafsirProgress = p);
        },
      );

      // التحقق من الجودة بعد التحميل
      if (LocalTafsirService.instance.totalEntries == 0) {
        throw Exception(l10n.errorUnknown);
      }

      // Success
      if (mounted) {
        setState(() {
          _statusMessage = l10n.initReady;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Initial Download Error: $e');
        final lastErr = LocalTafsirService.instance.lastError;
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _statusMessage =
              lastErr ?? '${l10n.initConnectionError}\n${e.toString()}';
        });
      }
    } finally {
      await _releaseWakelock();
    }
  }

  void _onProviderChange() {
    final provider = _downloadProvider;
    if (mounted && provider != null && provider.isDownloading) {
      setState(() {
        _mushafProgress = provider.downloadProgress;
      });
    }
  }

  String _getSizeEstimate(String? identifier) {
    if (identifier == 'qcf2_v4_woff2') return '58 MB';
    if (identifier == 'madani_old_v1') return '50 MB';
    if (identifier == 'shamarly_15lines') return '74 MB';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusMsg = _statusMessage.isEmpty
        ? l10n.initFirstTimeFiles
        : _statusMessage;

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Consumer<MushafMetadataProvider>(
            builder: (context, provider, child) {
              if (provider.availableMushafs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return RadioGroup<String?>(
                groupValue: _selectedMushafId,
                onChanged: (value) {
                  setState(() => _selectedMushafId = value);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Switcher
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: context.watch<SettingsProvider>().localeCode,
                          icon: const Icon(
                            Icons.language,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              context.read<SettingsProvider>().setLanguage(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.initApp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMsg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: _hasError ? Colors.red : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!_isDownloading) ...[
                      Expanded(
                        child: ListView.separated(
                          itemCount: provider.availableMushafs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final mushaf = provider.availableMushafs[index];
                            final isSelected =
                                _selectedMushafId == mushaf.identifier;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMushafId = mushaf.identifier;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.05,
                                        )
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Radio<String?>(
                                      value: mushaf.identifier,
                                      activeColor: AppColors.primary,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mushaf.nameArabic ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.initFirstTimeFiles,
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.initApproxSize(
                                              _getSizeEstimate(
                                                mushaf.identifier,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _startDownload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            l10n.initStartDownload,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Downloading State UI
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.initWait,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                LinearProgressIndicator(
                                  value: _mushafProgress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                  minHeight: 22,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                Text(
                                  '${(_mushafProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            Text(
                              l10n.initTafsir,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                LinearProgressIndicator(
                                  value: _tafsirProgress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4CAF50),
                                      ),
                                  minHeight: 22,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                Text(
                                  '${(_tafsirProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                _statusMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasError) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: _startDownload,
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(fontFamily: 'Tajawal'),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
