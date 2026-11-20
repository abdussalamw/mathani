import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mathani/core/di/service_locator.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/data/services/asr_service.dart';
import 'package:mathani/data/services/text_matching_service.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/data/services/recitation_diagnostic_service.dart';
import 'package:mathani/domain/entities/review_summary.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathani/core/services/recitation/recitation_model_downloader.dart';
import 'package:mathani/core/services/recitation/live_recitation_service.dart';
import 'package:mathani/core/services/recitation/recitation_phoneme_repository.dart';
import 'package:mathani/core/services/recitation/zipformer_alignment.dart';
import 'package:mathani/core/services/recitation/recitation_models.dart';
import 'package:mathani/core/services/recitation/zipformer_android_npu.dart';
import 'package:mathani/core/services/recitation/zipformer_engine.dart';

import 'dart:convert';

import 'package:mathani/data/providers/mushaf_navigation_provider.dart';

/// محركات التسميع المدعومة
enum RecitationEngine {
  zipformer, // المحرك الذكي السريع (Zipformer V3)
  whisper, // المحرك الكلاسيكي (Whisper) - 142MB (أرشيفي)
}

/// حالات شاشة التسميع
enum RecitationState {
  idle, // حالة الانتظار
  setup, // اختيار السورة/الآيات
  preparing, // التحضير وتهيئة العتاد والمسجل
  recording, // جارٍ التسجيل
  paused, // إيقاف مؤقت
  analyzing, // جارٍ التحليل
  result, // عرض النتائج
  history, // سجل الجلسات السابقة
  analytics, // لوحة التحليلات المتقدمة
  error, // حالة الخطأ أو الفشل
}

/// إعدادات ثابتة ومحددة لجلسة التسميع النشطة
class RecitationSessionConfig {
  final String sessionId;
  final RecitationEngine engine;
  final RecitationMode mode;
  final int? surahNumber;
  final String surahName;
  final int startAyah;
  final int endAyah;
  final DateTime startTime;

  const RecitationSessionConfig({
    required this.sessionId,
    required this.engine,
    required this.mode,
    this.surahNumber,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.startTime,
  });
}

/// وضع التسميع
enum RecitationMode {
  free, // حر — يبدأ من أي مكان والنظام يكتشف
  selected, // محدد — يختار السورة والآيات
}

/// مزود حالة قسم التسميع
class RecitationProvider extends ChangeNotifier {
  bool _disposed = false;
  ReviewSummary get reviewSummary => ReviewSummary.fromSessions(_allSessions);

  Future<bool> prepareSuggestedReview(RecitationSession session) async {
    final result = await _quranRepository.getSurahByNumber(session.surahNumber);
    final surah = result.fold((_) => null, (value) => value);
    if (_disposed || surah == null || surah.numberOfAyahs < 1) return false;
    await _prepareQuranText(surah.number);
    if (_disposed || (_quranTextCache[surah.number]?.isEmpty ?? true)) {
      return false;
    }
    _mode = RecitationMode.selected;
    _selectedSurah = surah.number;
    _selectedSurahName = surah.nameArabic;
    _totalAyahs = surah.numberOfAyahs;
    _startAyah = session.startAyah.clamp(1, _totalAyahs);
    _endAyah = session.endAyah.clamp(_startAyah, _totalAyahs);
    goToSetup();
    return true;
  }

  final QuranRepository _quranRepository;

  // الحالات والأخطاء
  RecitationState _state = RecitationState.idle;
  String? _errorMessage;
  RecitationDiagnosticIssue? _lastDiagnosticIssue;
  RecitationDiagnosticIssue? get lastDiagnosticIssue => _lastDiagnosticIssue;

  void _recordFailure(RecitationDiagnosticStage stage, String message) {
    _errorMessage = message;
    _lastDiagnosticIssue = (
      stage: stage,
      message: message,
      occurredAt: DateTime.now(),
    );
  }

  RecitationMode _mode = RecitationMode.free;
  RecitationSessionConfig? _activeSessionConfig;
  RecitationSessionConfig? get activeSessionConfig => _activeSessionConfig;

  // إعداد التسميع
  int? _selectedSurah;
  String _selectedSurahName = '';
  int _startAyah = 1;
  int _endAyah = 1;
  int _totalAyahs = 0;

  // ذاكرة مؤقتة لنصوص القرآن للمطابقة
  final Map<int, Map<int, String>> _quranTextCache = {};

  // التسجيل
  final Stopwatch _recordingClock = Stopwatch();
  Future<String?>? _starting;
  Future<void>? _finishing;
  Future<void>? _closing;
  bool _savingResult = false;
  bool _removingModel = false;

  bool get _hasSession =>
      _activeSessionConfig != null ||
      _starting != null ||
      _finishing != null ||
      _closing != null;
  int _matchedAyahsCount = 0;
  int _mistakesCount = 0;

  // التحليل
  double _analysisProgress = 0.0;
  String _analysisStep = '';

  // النتائج
  RecitationResult? _currentResult;

  // المتابعة اللحظية
  int? _matchedSurah;
  int? _matchedAyah;
  int _currentPage = 1;

  // السجل
  final List<RecitationSession> _sessions = [];

  // السجل الكامل للتحليلات
  final List<RecitationSession> _allSessions = [];
  List<RecitationSession> get allSessions => _allSessions;

  // المتابعة اللحظية المتقدمة والتلقين
  int _lastMatchedWordIndex = -1;
  String? _promptWord;
  String? get promptWord => _promptWord;
  Timer? _promptTimer;

  final Map<String, WordVerdict> _liveWordVerdicts = {};
  Map<String, WordVerdict> get liveWordVerdicts => _liveWordVerdicts;

  // مشغل صوت محلي للمقارنة
  final AudioPlayer _localPlayer = AudioPlayer();

  // النماذج والمحركات (Dual AI Engine Support)
  RecitationEngine _engine = RecitationEngine.zipformer;
  bool _enginePreferenceSet = false;
  RecitationEngine get engine => _engine;

  // حالة محرك Zipformer V3
  bool _isZipformerDownloaded = false;
  bool _isZipformerDownloading = false;
  double _zipformerDownloadProgress = 0.0;
  String _zipformerStatusText = '';

  bool get isZipformerDownloaded => _isZipformerDownloaded;
  bool get isZipformerDownloading => _isZipformerDownloading;
  double get zipformerDownloadProgress => _zipformerDownloadProgress;
  String get zipformerStatusText => _zipformerStatusText;

  // حالة محرك Whisper الكلاسيكي
  bool _isWhisperDownloaded = false;

  bool get isWhisperDownloaded => _isWhisperDownloaded;
  bool get isWhisperDownloading => false;
  double get whisperDownloadProgress => 0;

  // خصائص المحرك النشط حالياً
  bool get isCurrentEngineDownloaded => _engine == RecitationEngine.zipformer
      ? _isZipformerDownloaded
      : _isWhisperDownloaded;

  bool get isCurrentEngineDownloading =>
      _engine == RecitationEngine.zipformer ? _isZipformerDownloading : false;

  double get currentEngineProgress =>
      _engine == RecitationEngine.zipformer ? _zipformerDownloadProgress : 0;

  String get currentEngineName => _engine == RecitationEngine.zipformer
      ? 'Zipformer V3 (الموصى به)'
      : 'Whisper (الكلاسيكي)';

  String get currentEngineSize =>
      _engine == RecitationEngine.zipformer ? '164 MB' : '142 MB';

  // التوافق مع الكود السابق
  bool _hasMicrophonePermission = false;

  bool _isTajweedModelDownloaded = false;
  bool _isTajweedDownloading = false;
  double _tajweedDownloadProgress = 0.0;

  // ── Getters ──
  bool get isAsrModelDownloaded => isCurrentEngineDownloaded;
  bool get isAsrDownloading => isCurrentEngineDownloading;
  double get asrDownloadProgress => currentEngineProgress;
  bool get isNpuSupported => npuUnavailableReason == null;
  String? get npuUnavailableReason {
    if (!_liveService.isNpuSupported) {
      return 'التسميع غير متاح حاليًا. هذه النسخة من مثاني لم تُجهّز بعد لتشغيل Zipformer على NPU.';
    }
    return _usesPlatformNpu ? _platformNpuUnavailableReason : null;
  }

  DateTime? get lastVerifiedNpuAt => _lastVerifiedNpuAt;

  String get recitationAvailabilityLabel {
    if (_engine == RecitationEngine.whisper) return 'Whisper قيد التطوير';
    if (npuUnavailableReason case final String reason) return reason;
    if (isZipformerDownloading) return 'جارٍ تنزيل ملفات Zipformer';
    if (!isZipformerDownloaded) return 'ملفات Zipformer غير مكتملة';
    if (_lastVerifiedNpuAt != null) return 'اجتاز Zipformer اختبار NPU الأولي';
    return 'Zipformer مهيأ · يتحقق المحرك عند البدء';
  }

  bool get hasMicrophonePermission => _hasMicrophonePermission;
  bool get isInitializingRecording => _state == RecitationState.preparing;
  bool get isModelLoading => isInitializingRecording;
  bool get isTajweedModelDownloaded => _isTajweedModelDownloaded;
  bool get isTajweedDownloading => _isTajweedDownloading;
  double get tajweedDownloadProgress => _tajweedDownloadProgress;

  RecitationState get state => _state;
  String? get errorMessage => _errorMessage;
  RecitationMode get mode => _mode;
  int? get selectedSurah => _selectedSurah;
  String get selectedSurahName => _selectedSurahName;
  int get startAyah => _startAyah;
  int get endAyah => _endAyah;
  int get totalAyahs => _totalAyahs;
  bool get isRecording =>
      _state == RecitationState.recording || _state == RecitationState.paused;
  bool get isPaused => _state == RecitationState.paused;
  int get recordingDurationMs => _recordingClock.elapsedMilliseconds;
  int get matchedAyahsCount => _matchedAyahsCount;
  int get mistakesCount => _mistakesCount;
  double get analysisProgress => _analysisProgress;
  String get analysisStep => _analysisStep;
  RecitationResult? get currentResult => _currentResult;
  List<RecitationSession> get sessions => _sessions;
  int? get matchedSurah => _matchedSurah;
  int? get matchedAyah => _matchedAyah;
  int get currentPage => _currentPage;
  String get liveTranscript => _currentTranscript;

  /// نسبة الثقة الإجمالية الحالية (0.0 - 1.0) — تعتمد على نتيجة الجلسة إن وُجدت
  double get overallConfidence => _currentResult?.accuracy ?? 0.0;

  final TextMatchingService _matchingService = TextMatchingService();
  final LiveRecitationService _liveService;
  final bool _usesPlatformNpu;
  String? _platformNpuUnavailableReason = 'جارٍ فحص دعم NPU على الجهاز...';
  DateTime? _lastVerifiedNpuAt;
  final RecitationPhonemeRepository _phonemeRepository;
  late final ZipformerAlignment _alignment = ZipformerAlignment(
    _phonemeRepository,
  );

  RecitationProvider({
    LiveRecitationService? liveService,
    RecitationPhonemeRepository? phonemeRepository,
    QuranRepository? quranRepository,
    bool loadInitialState = true,
  }) : _usesPlatformNpu = liveService == null,
       _liveService =
           liveService ??
           LiveRecitationService(
             engine: const ZipformerEngine(
               openVerifiedNpuStream: ZipformerAndroidNpu.openStream,
             ),
           ),
       _phonemeRepository = phonemeRepository ?? RecitationPhonemeRepository(),
       _quranRepository = quranRepository ?? sl<QuranRepository>() {
    if (loadInitialState) {
      unawaited(_loadEnginePreference());
      unawaited(checkModelsState());
      unawaited(loadSessions());
    }
  }

  Future<void> _loadEnginePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _hasSession || _enginePreferenceSet) return;
      final engineStr = prefs.getString('recitation_engine');
      if (engineStr == 'whisper') {
        _engine = RecitationEngine.whisper;
      } else {
        _engine = RecitationEngine.zipformer;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading engine preference: $e');
    }
  }

  Future<void> setRecitationEngine(RecitationEngine newEngine) async {
    if (_disposed || newEngine == RecitationEngine.whisper) {
      return;
    }
    _enginePreferenceSet = true;
    _engine = newEngine;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recitation_engine', 'zipformer');
    } catch (e) {
      debugPrint('Error saving engine preference: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // الإعداد والمطابقة
  // ═══════════════════════════════════════════════

  void setMode(RecitationMode mode) {
    _mode = mode;
    if (mode == RecitationMode.free) {
      _selectedSurah = null;
      _selectedSurahName = '';
    }
    notifyListeners();
  }

  void selectSurah(int surahNumber, String surahName, int totalAyahs) async {
    _selectedSurah = surahNumber;
    _selectedSurahName = surahName;
    _totalAyahs = totalAyahs;
    _startAyah = 1;
    _endAyah = totalAyahs;

    // جلب نصوص السورة وتخزينها للمطابقة
    await _prepareQuranText(surahNumber);

    notifyListeners();
  }

  Future<void> _prepareQuranText(int surahNumber) async {
    final result = await _quranRepository.getAyahsForSurah(surahNumber);
    result.fold(
      (failure) => debugPrint('Error loading ayahs for matching: $failure'),
      (ayahs) {
        final Map<int, String> ayahMap = {};
        for (var a in ayahs) {
          ayahMap[a.ayahNumber] = a.text;
        }
        _quranTextCache[surahNumber] = ayahMap;
      },
    );
  }

  void setAyahRange(int start, int end) {
    _startAyah = start.clamp(1, _totalAyahs);
    _endAyah = end.clamp(_startAyah, _totalAyahs);
    notifyListeners();
  }

  void goToSetup() {
    if (_hasSession) return;
    _state = RecitationState.setup;
    _currentResult = null;
    notifyListeners();
  }

  void goToHistory() {
    if (_hasSession) return;
    _state = RecitationState.history;
    notifyListeners();
  }

  void retry(BuildContext context) {
    goToRecording(context);
  }

  Future<void> loadSessions() async {
    try {
      final isar = IsarService.instance.isar;
      final savedSessions = await isar.recitationSessions
          .where()
          .sortByCreatedAtDesc()
          .findAll();

      _allSessions.clear();
      _allSessions.addAll(savedSessions);

      _sessions.clear();
      _sessions.addAll(savedSessions.take(3));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recitation sessions: $e');
    }
  }

  Future<void> saveSession(RecitationSession session) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        await isar.recitationSessions.put(session);
      });
      await loadSessions();
    } catch (e) {
      debugPrint('Error saving recitation session: $e');
      _allSessions.insert(0, session);
      _sessions.clear();
      _sessions.addAll(_allSessions.take(3));
      notifyListeners();
    }
  }

  Future<void> checkModelsState() async {
    try {
      // 1. فحص محرك Zipformer V3 الذكي
      if (_usesPlatformNpu) {
        _platformNpuUnavailableReason =
            await ZipformerAndroidNpu.unavailableReason();
      }
      _isZipformerDownloaded =
          isNpuSupported && await RecitationModelDownloader.isModelReady();

      // 2. فحص محرك Whisper الكلاسيكي
      final directory = await getApplicationSupportDirectory();
      final asrDir = Directory('${directory.path}/ai_models/asr');
      bool asrExists = false;
      int onnxCount = 0;
      bool hasTokens = false;
      if (await asrDir.exists()) {
        final files = await asrDir.list(recursive: true).toList();
        for (var f in files) {
          if (f is File) {
            final size = await f.length();
            if (size > 1024 * 1024) {
              if (f.path.endsWith('.onnx')) {
                onnxCount++;
              }
            }
            if (size > 100 && f.path.endsWith('tokens.txt')) {
              hasTokens = true;
            }
          }
        }
        asrExists = onnxCount >= 2 && hasTokens;
      }
      _isWhisperDownloaded = asrExists;

      debugPrint(
        '🔍 Models Status: Zipformer=$_isZipformerDownloaded | Whisper=$_isWhisperDownloaded | Active=$_engine',
      );

      // التحقق من نموذج التجويد
      final tajweedDir = Directory('${directory.path}/ai_models/tajweed');
      if (await tajweedDir.exists()) {
        final files = await tajweedDir.list(recursive: true).toList();
        bool tajweedExists = false;
        for (var f in files) {
          if (f is File) {
            final size = await f.length();
            if (size > 1024 && f.path.endsWith('.tflite')) {
              tajweedExists = true;
            }
          }
        }
        _isTajweedModelDownloaded = tajweedExists;
      } else {
        _isTajweedModelDownloaded = false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error checking models state: $e');
    }
  }

  Future<void> checkMicrophonePermission() async {
    if (!isNpuSupported || _hasSession) return;
    try {
      _hasMicrophonePermission = await _liveService.hasPermission(
        request: true,
      );
      _errorMessage = _hasMicrophonePermission
          ? null
          : 'الرجاء منح إذن الميكروفون من إعدادات التطبيق.';
    } catch (_) {
      _errorMessage = 'تعذر التحقق من إذن الميكروفون.';
    }
    notifyListeners();
  }

  /// تنزيل ملفات محرك Zipformer V3 الذكي
  Future<void> downloadZipformerModel() async {
    if (_disposed ||
        !isNpuSupported ||
        _hasSession ||
        _removingModel ||
        _isZipformerDownloading ||
        _isZipformerDownloaded) {
      return;
    }

    _isZipformerDownloading = true;
    _zipformerDownloadProgress = 0.0;
    _zipformerStatusText = 'بدء تنزيل Zipformer V3...';
    notifyListeners();

    try {
      await RecitationModelDownloader.downloadRequiredFiles(
        onProgress: (progress, statusText) {
          _zipformerDownloadProgress = progress;
          _zipformerStatusText = statusText;
          notifyListeners();
        },
      );
      _phonemeRepository.invalidate();
      await checkModelsState();
      if (_isZipformerDownloaded) {
        _errorMessage = null;
      }
    } catch (e) {
      debugPrint('Error downloading Zipformer model: $e');
      final message = e is HttpException && e.message == 'HTTP 404'
          ? 'حزمة Zipformer لـNPU غير منشورة لمصدر التنزيل الحالي.'
          : 'تعذّر تنزيل ملفات Zipformer أو التحقق منها. راجع الاتصال ومساحة التخزين ثم أعد المحاولة.';
      _zipformerStatusText = message;
      _recordFailure(RecitationDiagnosticStage.download, message);
      _isZipformerDownloaded = false;
    } finally {
      _isZipformerDownloading = false;
      notifyListeners();
    }
  }

  Future<void> downloadWhisperModel() async {
    if (_hasSession) return;
    _errorMessage =
        'محرك Whisper قيد التطوير. محرك التسميع المعتمد هو Zipformer V3.';
    notifyListeners();
  }

  Future<void> downloadCurrentEngine() => _engine == RecitationEngine.zipformer
      ? downloadZipformerModel()
      : downloadWhisperModel();

  Future<void> downloadAsrModel() => downloadCurrentEngine();

  Future<void> deleteZipformerModel() async {
    if (_disposed || _hasSession || _removingModel || _isZipformerDownloading) {
      return;
    }
    _removingModel = true;
    try {
      final dir = await RecitationModelDownloader.getModelDirectory();
      if (await dir.exists()) await dir.delete(recursive: true);
      _lastVerifiedNpuAt = null;
      _zipformerStatusText = '';
      _phonemeRepository.invalidate();
      await checkModelsState();
    } catch (e) {
      debugPrint('Error deleting Zipformer model: $e');
      _errorMessage = 'تعذر حذف ملفات Zipformer.';
    } finally {
      _removingModel = false;
      notifyListeners();
    }
  }

  Future<void> deleteWhisperModel() async {
    if (_hasSession) return;
    try {
      final directory = await getApplicationSupportDirectory();
      final asrDir = Directory('${directory.path}/ai_models/asr');
      if (await asrDir.exists()) await asrDir.delete(recursive: true);
      await checkModelsState();
    } catch (e) {
      debugPrint('Error deleting Whisper model: $e');
    }
  }

  Future<void> downloadTajweedModel() async {
    if (_isTajweedDownloading || _isTajweedModelDownloaded) return;

    _isTajweedDownloading = true;
    _tajweedDownloadProgress = 0.0;
    notifyListeners();

    try {
      // فحص جودة تحميل ملف التجويد
      await checkModelsState();
    } catch (e) {
      debugPrint('Error downloading Tajweed model: $e');
      _isTajweedModelDownloaded = false;
    } finally {
      _isTajweedDownloading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════
  // التسجيل والتحليل اللحظي
  // ═══════════════════════════════════════════════

  String _currentTranscript = 'ابدأ القراءة الآن...';
  Timer? _partialUpdate;
  String? _pendingPhonemes;
  int _sessionSequence = 0;

  Future<void> goToRecording(BuildContext context) async {
    await startRecording();
  }

  int _calculatePage(int surah, int ayah) =>
      MushafNavigationProvider.pageForSurahAyah(surah, ayah) ?? 1;

  bool _isCurrent(RecitationSessionConfig session) =>
      !_disposed && identical(_activeSessionConfig, session);

  Future<String?> startRecording() async {
    if (_disposed || _hasSession || _removingModel || _isZipformerDownloading) {
      return null;
    }
    if (_engine == RecitationEngine.whisper) {
      _state = RecitationState.error;
      _recordFailure(
        RecitationDiagnosticStage.engine,
        'محرك Whisper قيد التطوير. اختر Zipformer V3 من إعدادات التسميع.',
      );
      notifyListeners();
      return null;
    }
    if (!isNpuSupported) {
      _state = RecitationState.error;
      _recordFailure(RecitationDiagnosticStage.npu, npuUnavailableReason!);
      notifyListeners();
      return null;
    }
    if (_mode == RecitationMode.selected && _selectedSurah == null) {
      _state = RecitationState.error;
      _errorMessage = 'اختر السورة ونطاق الآيات قبل بدء التسميع.';
      notifyListeners();
      return null;
    }

    final session = RecitationSessionConfig(
      sessionId: (++_sessionSequence).toString(),
      engine: _engine,
      mode: _mode,
      surahNumber: _mode == RecitationMode.selected ? _selectedSurah : null,
      surahName: _selectedSurahName,
      startAyah: _startAyah,
      endAyah: _endAyah,
      startTime: DateTime.now(),
    );
    _activeSessionConfig = session;
    _state = RecitationState.preparing;
    _analysisStep = 'جارٍ تجهيز محرك التسميع والإذن بالتسجيل...';
    _analysisProgress = 0;
    _errorMessage = null;
    _currentResult = null;
    _matchedSurah = session.surahNumber;
    _matchedAyah = session.surahNumber == null ? null : session.startAyah;
    _currentPage = _matchedSurah == null
        ? 1
        : _calculatePage(_matchedSurah!, _matchedAyah!);
    _matchedAyahsCount = 0;
    _mistakesCount = 0;
    _lastMatchedWordIndex = -1;
    _liveWordVerdicts.clear();
    _promptWord = null;
    _promptTimer?.cancel();
    _recordingClock.reset();

    final task = Future<String?>.microtask(() => _openSession(session));
    _starting = task;
    notifyListeners();
    try {
      return await task;
    } finally {
      _starting = null;
    }
  }

  Future<String?> _openSession(RecitationSessionConfig session) async {
    var stage = RecitationDiagnosticStage.npu;
    try {
      if (!_isCurrent(session)) return null;
      await _liveService.prepare();
      if (!_isCurrent(session)) return null;
      _lastVerifiedNpuAt = DateTime.now();
      stage = RecitationDiagnosticStage.reference;
      if (!await _phonemeRepository.load()) {
        throw StateError('ملف الفونيمات غير متاح أو تالف.');
      }
      if (!_isCurrent(session)) return null;
      stage = RecitationDiagnosticStage.permission;
      final allowed = await _liveService.hasPermission(request: true);
      if (!_isCurrent(session)) return null;
      _hasMicrophonePermission = allowed;
      if (!allowed) {
        throw StateError('لا يمكن التسجيل دون إذن الميكروفون.');
      }

      stage = RecitationDiagnosticStage.recording;
      final path = await _liveService.start(
        onPartial: (phonemes) => _queueHypothesis(session, phonemes),
        onError: (_, _) {
          if (_isCurrent(session)) {
            unawaited(
              _closeSession(
                'تعذر متابعة الصوت عبر محرك التسميع.',
                stage: RecitationDiagnosticStage.streaming,
              ),
            );
          }
        },
      );
      if (!_isCurrent(session)) return null;
      _state = RecitationState.recording;
      _currentTranscript = 'جارٍ الاستماع...';
      _recordingClock.start();
      notifyListeners();
      return path;
    } catch (error) {
      if (_isCurrent(session)) {
        try {
          await _liveService.cancel();
        } catch (_) {
          // The session still reports the original start failure.
        }
        if (_isCurrent(session)) {
          _activeSessionConfig = null;
          _state = RecitationState.error;
          final message = switch (stage) {
            RecitationDiagnosticStage.reference =>
              'ملف الفونيمات غير متاح أو تالف.',
            RecitationDiagnosticStage.permission =>
              'تعذّر التسجيل. راجع إذن الميكروفون.',
            RecitationDiagnosticStage.recording =>
              'تعذّر فتح الميكروفون لبدء الجلسة.',
            _ => error is ZipformerNpuUnavailable ? error.message : 'تعذّر تهيئة Zipformer على NPU. افحص تهيئة المزوّد وملفات النموذج.',
          };
          _recordFailure(stage, message);
          notifyListeners();
        }
      }
      return null;
    }
  }

  List<ZipformerVerseAlignment> _align(
    RecitationSessionConfig session,
    String phonemes,
  ) => _alignment.align(
    phonemes,
    surah: session.surahNumber,
    startAyah: session.mode == RecitationMode.selected
        ? session.startAyah
        : null,
    endAyah: session.mode == RecitationMode.selected ? session.endAyah : null,
  );

  void _queueHypothesis(RecitationSessionConfig session, String phonemes) {
    if (!_isCurrent(session) || _state != RecitationState.recording) return;
    if (phonemes == _pendingPhonemes ||
        (_pendingPhonemes == null && phonemes == _currentTranscript)) {
      return;
    }
    _pendingPhonemes = phonemes;
    _partialUpdate ??= Timer(const Duration(milliseconds: 180), () {
      _partialUpdate = null;
      final next = _pendingPhonemes;
      _pendingPhonemes = null;
      if (next == null ||
          next == _currentTranscript ||
          !_isCurrent(session) ||
          _state != RecitationState.recording) {
        return;
      }
      try {
        final verses = _align(session, next);
        if (verses.isNotEmpty) {
          final parts = verses.last.verse.verseKey.split(':');
          final surah = int.parse(parts[0]);
          final ayah = int.parse(parts[1]);
          _matchedSurah = surah;
          _matchedAyah = ayah;
          _currentPage = _calculatePage(surah, ayah);
        }
        _lastMatchedWordIndex = -1;
        final words = _confirmedWords(verses);
        _liveWordVerdicts.clear();
        for (final word in words) {
          final key =
              '${word.surahNumber}_${word.ayahNumber}_${word.wordIndex + 1}';
          _liveWordVerdicts[key] = word.verdict;
          if (word.surahNumber == _matchedSurah &&
              word.ayahNumber == _matchedAyah) {
            _lastMatchedWordIndex = word.wordIndex;
          }
        }
        _matchedAyahsCount = verses.where((v) => v.isComplete).length;
        _mistakesCount = words
            .where(
              (word) =>
                  word.verdict == WordVerdict.incorrect ||
                  word.verdict == WordVerdict.skipped,
            )
            .length;
        _currentTranscript = next;
        notifyListeners();
      } catch (_) {
        unawaited(
          _closeSession(
            'تعذرت مطابقة التلاوة مع النص المرجعي.',
            stage: RecitationDiagnosticStage.matching,
          ),
        );
      }
    });
  }

  List<MatchedWord> _confirmedWords(List<ZipformerVerseAlignment> verses) {
    final words = <MatchedWord>[];
    for (final item in verses) {
      final parts = item.verse.verseKey.split(':');
      final surah = int.parse(parts[0]);
      final ayah = int.parse(parts[1]);
      for (final word in item.words) {
        final verdict = switch (word.status) {
          WordRecitationStatus.matched => WordVerdict.correct,
          WordRecitationStatus.omitted => WordVerdict.skipped,
          WordRecitationStatus.incorrect => WordVerdict.incorrect,
          WordRecitationStatus.current || WordRecitationStatus.unspoken => null,
        };
        if (verdict == null) continue;
        words.add(
          MatchedWord(
            spokenWord: word.recognizedPhonemes,
            expectedWord: word.wordText,
            surahNumber: surah,
            ayahNumber: ayah,
            wordIndex: word.wordIndex,
            similarity: word.similarity,
            verdict: verdict,
          ),
        );
      }
    }
    return words;
  }

  void _clearPartialUpdate() {
    _partialUpdate?.cancel();
    _partialUpdate = null;
    _pendingPhonemes = null;
  }

  Future<void> pauseRecording() async {
    final session = _activeSessionConfig;
    if (session == null || _state != RecitationState.recording) return;
    try {
      await _liveService.pause();
      if (!_isCurrent(session) || _state != RecitationState.recording) return;
      _recordingClock.stop();
      _clearPartialUpdate();
      _state = RecitationState.paused;
      notifyListeners();
    } catch (_) {
      if (_isCurrent(session)) {
        await _closeSession('تعذر إيقاف التسجيل مؤقتًا.');
      }
    }
  }

  Future<void> resumeRecording() async {
    final session = _activeSessionConfig;
    if (session == null || _state != RecitationState.paused) return;
    try {
      await _liveService.resume();
      if (!_isCurrent(session) || _state != RecitationState.paused) return;
      _recordingClock.start();
      _state = RecitationState.recording;
      notifyListeners();
    } catch (_) {
      if (_isCurrent(session)) await _closeSession('تعذر استئناف التسجيل.');
    }
  }

  Future<double> getRecordingAmplitude() async {
    try {
      return await _liveService.getAmplitude();
    } catch (_) {
      return 0;
    }
  }

  Future<void> stopRecording() async {
    final session = _activeSessionConfig;
    if (session == null || !isRecording || _finishing != null) return;
    _recordingClock.stop();
    _clearPartialUpdate();
    _state = RecitationState.analyzing;
    _analysisStep = 'جارٍ إنهاء تحليل التلاوة...';
    _analysisProgress = 0.5;
    final task = Future<void>.microtask(() => _finalizeSession(session));
    _finishing = task;
    notifyListeners();
    try {
      await task;
    } finally {
      _finishing = null;
    }
  }

  Future<void> _finalizeSession(RecitationSessionConfig session) async {
    String? ownedPath;
    var stage = RecitationDiagnosticStage.finalization;
    var message = 'تعذّر إنهاء التحليل. يرجى المحاولة مرة أخرى.';
    try {
      if (!_isCurrent(session)) return;
      final result = await _liveService.finish();
      ownedPath = result.audioPath;
      if (!_isCurrent(session)) return;
      if (ownedPath == null) {
        message = 'التسجيل لا يحتوي على عينات صوتية.';
        throw StateError(message);
      }
      stage = RecitationDiagnosticStage.matching;
      message = 'تعذّر تحديد كلمات مؤكدة من التسجيل.';
      final verses = _align(session, result.phonemes);
      final words = _confirmedWords(verses);
      if (words.isEmpty) {
        throw StateError(message);
      }
      final first = words.first;
      final last = words.lastWhere(
        (word) => word.surahNumber == first.surahNumber,
      );
      final match = MatchResult(
        surahNumber: first.surahNumber,
        surahName: verses.first.verse.surahNameAr,
        startAyah: first.ayahNumber,
        endAyah: last.ayahNumber,
        matchedWords: words,
        overallConfidence:
            words.fold<double>(0, (sum, word) => sum + word.similarity) /
            words.length,
      );
      stage = RecitationDiagnosticStage.finalization;
      message = 'تعذّر إكمال نتيجة الجلسة.';
      final committed = await _finishAnalysis(
        match,
        result.phonemes,
        ownedPath,
        session: session,
      );
      if (committed) ownedPath = null;
    } catch (_) {
      if (_isCurrent(session)) {
        _activeSessionConfig = null;
        _liveWordVerdicts.clear();
        _state = RecitationState.error;
        _recordFailure(stage, message);
        notifyListeners();
      }
    } finally {
      if (ownedPath != null) {
        try {
          final file = File(ownedPath);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // The recorder transferred only the current, uncommitted WAV.
        }
      }
    }
  }

  /// تحميل نتيجة تجريبية لمعاينة واجهة التقرير وتلوين الكلمات على المحاكي
  Future<void> loadDemoResult() async {
    if (_hasSession) return;
    _selectedSurah = 1;
    _selectedSurahName = 'الفاتحة';
    _startAyah = 1;
    _endAyah = 3;

    // تجهيز كلمات القرآن
    await _prepareQuranText(1);

    // محاكاة كلمات قالها المستخدم (مع خطأ في كلمة ونسيان كلمة)
    final mockAsrWords = [
      const AsrWord(text: 'بسم', startMs: 0, endMs: 400),
      const AsrWord(text: 'الله', startMs: 400, endMs: 800),
      const AsrWord(text: 'الرحمن', startMs: 800, endMs: 1400),
      const AsrWord(text: 'الرحيم', startMs: 1400, endMs: 2000),
      const AsrWord(text: 'الحمد', startMs: 2200, endMs: 2600),
      const AsrWord(text: 'لله', startMs: 2600, endMs: 3000),
      const AsrWord(text: 'رب', startMs: 3000, endMs: 3400),
      const AsrWord(text: 'العالمين', startMs: 3400, endMs: 4000),
      const AsrWord(text: 'الرحمن', startMs: 4200, endMs: 4800),
      // نسي كلمة "الرحيم" في الآية 3
    ];

    final matchResult = await _matchingService.matchTranscript(
      asrWords: mockAsrWords,
      quranText: _quranTextCache,
      hintSurah: 1,
      hintStartAyah: 1,
      hintEndAyah: 3,
    );

    await _finishAnalysis(
      matchResult,
      'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن',
      null,
    );
  }

  Future<bool> _finishAnalysis(
    MatchResult matchResult,
    String rawTranscript,
    String? audioPath, {
    RecitationSessionConfig? session,
  }) async {
    if (session != null && !_isCurrent(session)) return false;
    if (session == null && (_disposed || _hasSession)) return false;

    final words = matchResult.matchedWords.map((word) {
      return WordResult(
        spokenWord: word.spokenWord,
        expectedWord: word.expectedWord,
        surahNumber: word.surahNumber,
        ayahNumber: word.ayahNumber,
        wordIndex: word.wordIndex,
        verdict: word.verdict,
        confidence: word.similarity,
        startTimeMs: word.startMs,
        endTimeMs: word.endMs,
      );
    }).toList();
    final result = RecitationResult(
      words: words,
      surahNumber: matchResult.surahNumber,
      surahName: matchResult.surahName,
      startAyah: matchResult.startAyah,
      endAyah: matchResult.endAyah,
      durationMs: session == null ? 12000 : recordingDurationMs,
      rawTranscript: rawTranscript,
      audioPath: audioPath,
    );

    if (session != null) {
      _savingResult = true;
      try {
        final record = RecitationSession()
          ..surahNumber = result.surahNumber
          ..surahName = result.surahName
          ..startAyah = result.startAyah
          ..endAyah = result.endAyah
          ..mode = session.mode == RecitationMode.free ? 'free' : 'selected'
          ..accuracyPercent = result.accuracyPercent
          ..totalWords = result.totalWords
          ..correctWords = result.correctWords
          ..durationSeconds = (result.durationMs / 1000).round()
          ..overallGrade = result.overallGrade
          ..rawTranscript = result.rawTranscript
          ..resultJson = jsonEncode({
            ...result.toJson(),
            'engine': session.engine.name,
          })
          ..createdAt = DateTime.now();
        await saveSession(record);
      } finally {
        _savingResult = false;
      }
      if (!_isCurrent(session)) return true;
    }

    _currentResult = result;
    _liveWordVerdicts.clear();
    for (final word in words) {
      final key =
          '${word.surahNumber}_${word.ayahNumber}_${word.wordIndex + 1}';
      _liveWordVerdicts[key] = word.verdict;
    }
    _activeSessionConfig = null;
    _analysisProgress = 1;
    _state = RecitationState.result;
    notifyListeners();
    return true;
  }

  Future<void> cancelRecording() => _closeSession(null);

  Future<void> _closeSession(
    String? error, {
    RecitationDiagnosticStage stage = RecitationDiagnosticStage.cleanup,
  }) async {
    final closing = _closing;
    if (closing != null) return closing;
    if (_savingResult) {
      await _finishing;
      return;
    }
    if (_activeSessionConfig == null) return;
    _activeSessionConfig = null;
    _recordingClock.stop();
    _clearPartialUpdate();
    _promptTimer?.cancel();
    _promptWord = null;
    _liveWordVerdicts.clear();
    _matchedSurah = null;
    _matchedAyah = null;
    final start = _starting;
    final finish = _finishing;
    final task = Future<void>.microtask(() async {
      try {
        await _liveService.cancel();
      } finally {
        await start;
        await finish;
      }
    });
    _closing = task;
    String? closeError = error;
    try {
      await task;
    } catch (_) {
      closeError ??= 'تعذر إنهاء موارد التسجيل.';
    } finally {
      _closing = null;
      if (closeError == null) {
        _errorMessage = null;
      } else {
        _recordFailure(stage, closeError);
      }
      _state = closeError == null
          ? RecitationState.setup
          : RecitationState.error;
      notifyListeners();
    }
  }

  Future<String?> startRecitationFromMinibar() => startRecording();

  void reset() {
    if (_hasSession) {
      unawaited(cancelRecording());
      return;
    }
    _state = RecitationState.setup;
    _currentResult = null;
    _errorMessage = null;
    _promptWord = null;
    _promptTimer?.cancel();
    _liveWordVerdicts.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ميزات المساعدة والتلقين والمقارنة الصوتية والتحليلات
  // ═══════════════════════════════════════════════

  String? getNextWord() {
    final session = _activeSessionConfig;
    int surah;
    int ayah;
    int nextWordIdx = 0;

    if (session?.mode == RecitationMode.selected &&
        session!.surahNumber != null) {
      surah = session.surahNumber!;
      if (_matchedSurah == surah && _matchedAyah != null) {
        ayah = _matchedAyah!;
        nextWordIdx = _lastMatchedWordIndex + 1;
      } else {
        ayah = session.startAyah;
        nextWordIdx = 0;
      }
    } else {
      // الوضع الحر
      if (_matchedSurah != null && _matchedAyah != null) {
        surah = _matchedSurah!;
        ayah = _matchedAyah!;
        nextWordIdx = _lastMatchedWordIndex + 1;
      } else {
        return null;
      }
    }

    final surahMap = _quranTextCache[surah];
    final ayahText =
        surahMap?[ayah] ??
        _phonemeRepository.getVersePhonemes(surah, ayah)?.ayaText;
    if (ayahText == null) return null;

    final words = ayahText
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();
    if (nextWordIdx < words.length) {
      return words[nextWordIdx];
    } else {
      // الانتقال للآية التالية
      final nextAyah = ayah + 1;
      if (session?.mode == RecitationMode.selected &&
          nextAyah > session!.endAyah) {
        return null;
      }
      final nextAyahText =
          surahMap?[nextAyah] ??
          _phonemeRepository.getVersePhonemes(surah, nextAyah)?.ayaText;
      if (nextAyahText != null) {
        final nextWords = nextAyahText
            .split(' ')
            .where((w) => w.trim().isNotEmpty)
            .toList();
        if (nextWords.isNotEmpty) {
          return nextWords.first;
        }
      }
    }
    return null;
  }

  void triggerPrompt() {
    final next = getNextWord();
    if (next != null) {
      _promptWord = next;
      notifyListeners();

      _promptTimer?.cancel();
      _promptTimer = Timer(const Duration(seconds: 4), () {
        _promptWord = null;
        notifyListeners();
      });
    }
  }

  // تشغيل تسجيل المستخدم للكلمة
  Future<void> playUserWordAudio(String audioPath, WordResult word) async {
    final start = word.startTimeMs;
    final end = word.endTimeMs;
    if (start == null || end == null || start < 0 || end <= start) return;
    try {
      await _localPlayer.stop();
      if (!await File(audioPath).exists()) return;
      await _localPlayer.setFilePath(audioPath);
      await _localPlayer.setClip(
        start: Duration(milliseconds: start),
        end: Duration(milliseconds: end),
      );
      await _localPlayer.play();
    } catch (e) {
      debugPrint('Error playing user audio: $e');
    }
  }

  Future<void> stopUserAudio() async {
    await _localPlayer.stop();
  }

  // مشغل تلاوة الشيخ
  final AudioPlayer _sheikhPlayer = AudioPlayer();
  bool _isSheikhPlaying = false;
  bool get isSheikhPlaying => _isSheikhPlaying;

  Future<void> playSheikhAyah(int surah, int ayah) async {
    try {
      await _sheikhPlayer.stop();
      final url =
          'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee/murattal/${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
      await _sheikhPlayer.setUrl(url);
      _isSheikhPlaying = true;
      notifyListeners();

      _sheikhPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isSheikhPlaying = false;
          notifyListeners();
        }
      });

      await _sheikhPlayer.play();
    } catch (e) {
      debugPrint('Error playing sheikh audio: $e');
      _isSheikhPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopSheikhAudio() async {
    await _sheikhPlayer.stop();
    _isSheikhPlaying = false;
    notifyListeners();
  }

  // الانتقال لشاشة التحليلات
  void goToAnalytics() {
    if (_hasSession) return;
    _state = RecitationState.analytics;
    notifyListeners();
  }

  // تحديد جلسة سابقة لاستعراض نتائجها
  void selectSession(RecitationSession session) {
    if (_hasSession) return;
    if (session.resultJson != null && session.resultJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(session.resultJson!);
        _currentResult = RecitationResult(
          words: (json['words'] as List<dynamic>)
              .map(
                (w) => WordResult(
                  spokenWord: w['spoken'] ?? '',
                  expectedWord: w['expected'] ?? '',
                  surahNumber: w['surah'] ?? 1,
                  ayahNumber: w['ayah'] ?? 1,
                  wordIndex: w['wordIndex'] ?? 0,
                  verdict: WordVerdict.values.firstWhere(
                    (v) => v.name == w['verdict'],
                    orElse: () => WordVerdict.skipped,
                  ),
                  confidence: w['confidence'] ?? 1.0,
                  startTimeMs: w['startMs'],
                  endTimeMs: w['endMs'],
                ),
              )
              .toList(),
          surahNumber: json['surah'] ?? 1,
          surahName: json['surahName'] ?? '',
          startAyah: json['startAyah'] ?? 1,
          endAyah: json['endAyah'] ?? 1,
          durationMs: json['durationMs'] ?? 0,
          rawTranscript: json['rawTranscript'] ?? '',
          analyzedAt: DateTime.parse(json['analyzedAt']),
          audioPath: json['audioPath'],
        );

        // إعادة ملء التلوين
        _liveWordVerdicts.clear();
        for (var w in _currentResult!.words) {
          final key = "${w.surahNumber}_${w.ayahNumber}_${w.wordIndex + 1}";
          _liveWordVerdicts[key] = w.verdict;
        }

        _state = RecitationState.result;
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing session resultJson: $e');
      }
    } else {
      _currentResult = RecitationResult(
        words: [],
        surahNumber: session.surahNumber,
        surahName: session.surahName,
        startAyah: session.startAyah,
        endAyah: session.endAyah,
        durationMs: session.durationSeconds * 1000,
        rawTranscript: session.rawTranscript,
      );
      _state = RecitationState.result;
      notifyListeners();
    }
  }

  // ── حسابات لوحة التحليلات ──

  int get currentStreak {
    if (_allSessions.isEmpty) return 0;

    final dates =
        _allSessions
            .map(
              (s) => DateTime(
                s.createdAt.year,
                s.createdAt.month,
                s.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates.isEmpty) return 0;
    if (dates.first != today && dates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  double get memorizationProgress {
    if (_allSessions.isEmpty) return 0.0;
    final excellentSurahs = _allSessions
        .where((s) => s.accuracyPercent >= 80)
        .map((s) => s.surahNumber)
        .toSet();
    return excellentSurahs.length / 114;
  }

  List<Map<String, dynamic>> get hotspotSurahs {
    if (_allSessions.isEmpty) return [];

    final Map<int, List<int>> surahAccuracies = {};
    final Map<int, String> surahNames = {};

    for (var s in _allSessions) {
      surahAccuracies
          .putIfAbsent(s.surahNumber, () => [])
          .add(s.accuracyPercent);
      surahNames[s.surahNumber] = s.surahName;
    }

    final List<Map<String, dynamic>> hotspots = [];
    surahAccuracies.forEach((surahNum, accuracies) {
      final avgAcc = accuracies.reduce((a, b) => a + b) / accuracies.length;
      hotspots.add({
        'number': surahNum,
        'name': surahNames[surahNum] ?? 'غير محدد',
        'accuracy': avgAcc.round(),
      });
    });

    hotspots.sort(
      (a, b) => (a['accuracy'] as num).compareTo(b['accuracy'] as num),
    );
    return hotspots.take(5).toList();
  }

  int get totalWordsRead {
    return _allSessions.fold(0, (sum, s) => sum + s.totalWords);
  }

  int get totalDurationSeconds {
    return _allSessions.fold(0, (sum, s) => sum + s.durationSeconds);
  }

  int get averageAccuracy {
    if (_allSessions.isEmpty) return 0;
    final sum = _allSessions.fold(0, (sum, s) => sum + s.accuracyPercent);
    return (sum / _allSessions.length).round();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _clearPartialUpdate();
    _promptTimer?.cancel();
    unawaited(cancelRecording().whenComplete(_liveService.dispose));
    unawaited(_localPlayer.dispose());
    unawaited(_sheikhPlayer.dispose());
    super.dispose();
  }
}
