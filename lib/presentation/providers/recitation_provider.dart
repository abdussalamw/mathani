import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mathani/core/di/service_locator.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mathani/data/services/asr_service.dart';
import 'package:mathani/data/services/text_matching_service.dart';
import 'package:mathani/data/services/audio_recorder_service.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/data/services/mushaf_downloader_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:mathani/data/providers/mushaf_navigation_provider.dart';

/// حالات شاشة التسميع
enum RecitationState {
  idle,       // حالة الانتظار
  setup,      // اختيار السورة/الآيات
  recording,  // جارٍ التسجيل
  analyzing,  // جارٍ التحليل
  result,     // عرض النتائج
  history,    // سجل الجلسات السابقة
  analytics,  // لوحة التحليلات المتقدمة
  error,      // حالة الخطأ
}

/// وضع التسميع
enum RecitationMode {
  free,       // حر — يبدأ من أي مكان والنظام يكتشف
  selected,   // محدد — يختار السورة والآيات
}

/// مزود حالة قسم التسميع
class RecitationProvider extends ChangeNotifier {
  final QuranRepository _quranRepository = sl<QuranRepository>();
  
  // الحالات والأخطاء
  RecitationState _state = RecitationState.idle;
  String? _errorMessage;
  RecitationMode _mode = RecitationMode.free;
  
  // إعداد التسميع
  int? _selectedSurah;
  String _selectedSurahName = '';
  int _startAyah = 1;
  int _endAyah = 1;
  int _totalAyahs = 0;
  
  // ذاكرة مؤقتة لنصوص القرآن للمطابقة
  final Map<int, Map<int, String>> _quranTextCache = {};

  // التسجيل
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDurationMs = 0;
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

  // النماذج (Real AI Models)
  bool _isAsrModelDownloaded = false;
  bool _isAsrDownloading = false;
  double _asrDownloadProgress = 0.0;
  bool _isNpuSupported = true;
  bool _hasMicrophonePermission = false;
  bool _isInitializingRecording = false;
  bool _isModelLoading = false; // جاري تحميل النموذج في الذاكرة

  bool _isTajweedModelDownloaded = false;
  bool _isTajweedDownloading = false;
  double _tajweedDownloadProgress = 0.0;

  // ── Getters ──
  bool get isAsrModelDownloaded => _isAsrModelDownloaded;
  bool get isAsrDownloading => _isAsrDownloading;
  double get asrDownloadProgress => _asrDownloadProgress;
  bool get isNpuSupported => _isNpuSupported;
  bool get hasMicrophonePermission => _hasMicrophonePermission;
  bool get isInitializingRecording => _isInitializingRecording;
  bool get isModelLoading => _isModelLoading;
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
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordingDurationMs => _recordingDurationMs;
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

  // Services
  final AsrService _asrService = AsrService();
  final TextMatchingService _matchingService = TextMatchingService();
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  static const String _asrModelZipUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tadabur-whisper-mobile.zip';
  static const String _asrTokensUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tokens.txt';
  
  // نموذج التجويد
  static const String _tajweedModelUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tajweed_classifier.tflite';

  RecitationProvider() {
    checkModelsState();
    loadSessions();
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
      }
    );
  }

  void setAyahRange(int start, int end) {
    _startAyah = start.clamp(1, _totalAyahs);
    _endAyah = end.clamp(_startAyah, _totalAyahs);
    notifyListeners();
  }

  void goToSetup() {
    _state = RecitationState.setup;
    _currentResult = null;
    notifyListeners();
  }

  void goToHistory() {
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
      final directory = await getApplicationSupportDirectory();
      
      // التحقق من نماذج ASR (نبحث عن الملفات الأساسية وحجمها)
      final asrDir = Directory('${directory.path}/ai_models/asr');
      bool asrExists = false;
      int onnxCount = 0;
      bool hasTokens = false;
      if (await asrDir.exists()) {
        final files = await asrDir.list(recursive: true).toList();
        for (var f in files) {
          if (f is File) {
            final size = await f.length();
            if (size > 1024 * 1024) { // ملفات النموذج أكبر من 1 ميجابايت (عادة 90 ميجا و190 ميجا)
              if (f.path.endsWith('.onnx')) {
                onnxCount++;
              }
            }
            if (size > 100 && f.path.endsWith('tokens.txt')) {
              hasTokens = true;
            }
          }
        }
        // Whisper يحتاج إلى ملفين ONNX على الأقل وملف tokens
        asrExists = onnxCount >= 2 && hasTokens;
      }
      _isAsrModelDownloaded = asrExists;
      debugPrint('🔍 ASR Model: $_isAsrModelDownloaded | ONNX=$onnxCount | tokens=$hasTokens | path=${asrDir.path}');
    
      // التحقق من الـ NPU (NNAPI على أندرويد)
      if (Platform.isAndroid) {
        _isNpuSupported = await _asrService.checkNpuSupport();
      } else {
        _isNpuSupported = true;
      }
      
      // التحقق من نموذج التجويد (حد الحجم 1KB فقط — الملف قد يكون أصغر من 1MB)
      final tajweedDir = Directory('${directory.path}/ai_models/tajweed');
      if (await tajweedDir.exists()) {
        final files = await tajweedDir.list(recursive: true).toList();
        bool tajweedExists = false;
        for (var f in files) {
          if (f is File) {
            final size = await f.length();
            debugPrint('📂 Tajweed file: ${f.path.split('/').last} | ${(size/1024).toStringAsFixed(1)} KB');
            if (size > 1024 && f.path.endsWith('.tflite')) {
              tajweedExists = true;
            }
          }
        }
        _isTajweedModelDownloaded = tajweedExists;
      } else {
        _isTajweedModelDownloaded = false;
      }
      debugPrint('🔍 Tajweed Model: $_isTajweedModelDownloaded');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking models state: $e');
    }
  }

  Future<void> checkMicrophonePermission() async {
    try {
      // Request microphone permission at runtime (required for Android 6.0+)
      final status = await Permission.microphone.request();
      _hasMicrophonePermission = status.isGranted;
      
      if (!status.isGranted) {
        _errorMessage = 'الرجاء منح إذونات الميكروفون من إعدادات التطبيق.';
      } else {
        _errorMessage = null;
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      // Fallback to just checking if permission was granted
      _hasMicrophonePermission = await AudioRecorderService().hasPermission();
    }
    notifyListeners();
  }

  Future<void> downloadAsrModel() async {
    if (_isAsrDownloading || _isAsrModelDownloaded) return;
    
    _isAsrDownloading = true;
    _asrDownloadProgress = 0.0;
    notifyListeners();

    try {
      final directory = await getApplicationSupportDirectory();
      final destinationPath = '${directory.path}/ai_models/asr';

      // 1. تحميل وفك ضغط المحرك الأساسي (Zip)
      await MushafDownloaderService.downloadAndExtract(
        url: _asrModelZipUrl,
        destinationPath: destinationPath,
        onProgress: (progress) {
          _asrDownloadProgress = progress * 0.8; // يمثل 80% من العملية
          notifyListeners();
        },
      );

      // 2. تحميل ملف الـ Tokens مباشرة لنفس المجلد
      await MushafDownloaderService.downloadAndExtract(
        url: _asrTokensUrl,
        destinationPath: destinationPath,
        onProgress: (progress) {
          _asrDownloadProgress = 0.8 + (progress * 0.2); // يمثل 20% المتبقية
          notifyListeners();
        },
      );

      // فحص جودة التحميل والتأكد من وجود الملفات فعلياً وحجمها
      await checkModelsState();
    } catch (e) {
      debugPrint('Error downloading ASR models: $e');
      _isAsrModelDownloaded = false;
    } finally {
      _isAsrDownloading = false;
      notifyListeners();
    }
  }

  Future<void> downloadTajweedModel() async {
    if (_isTajweedDownloading || _isTajweedModelDownloaded) return;
    
    _isTajweedDownloading = true;
    _tajweedDownloadProgress = 0.0;
    notifyListeners();

    try {
      final directory = await getApplicationSupportDirectory();
      final destinationPath = '${directory.path}/ai_models/tajweed';

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
  Timer? _liveAnalysisTimer;
  bool _isLiveAnalyzing = false; // قفل ضد تكدس استدعاءات التحليل اللحظي

  Future<void> goToRecording(BuildContext context) async {
    if (_isInitializingRecording) return;

    debugPrint('🚀 محاولة الانتقال لشاشة التسجيل...');
    _isInitializingRecording = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isAsrModelDownloaded) {
        debugPrint('⚠️ النماذج غير محملة');
        _errorMessage = 'النماذج غير محملة. يرجى التوجه لمركز التحميلات.';
        return;
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('⚠️ لا توجد صلاحية ميكروفون - محاولة طلب الإذونات');
        // Try requesting permission
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          debugPrint('⚠️ تم رفض إذونات الميكروفون');
          _errorMessage = 'لا يمكن البدء بدون صلاحية الميكروفون. يرجى منح الصلاحية من إعدادات النظام.';
          return;
        }
      }

      _state = RecitationState.recording;
      _matchedAyahsCount = 0;
      _mistakesCount = 0;
      _liveWordVerdicts.clear();
      _lastMatchedWordIndex = -1;
      _promptWord = null;
      _promptTimer?.cancel();
      debugPrint('✅ الحالة تغيرت إلى Recording');

      // حساب الصفحة الابتدائية
      if (_mode == RecitationMode.selected && _selectedSurah != null) {
        _matchedSurah = _selectedSurah;
        _matchedAyah = _startAyah;
        _currentPage = _calculatePage(_selectedSurah!, _startAyah);
      } else {
        _matchedSurah = null;
        _matchedAyah = null;
        _currentPage = 1;
      }
    } catch (e) {
      debugPrint('❌ خطأ في goToRecording: $e');
      _errorMessage = 'خطأ غير متوقع: ${e.toString()}';
    } finally {
      _isInitializingRecording = false;
      notifyListeners();
    }
  }

  int _calculatePage(int surah, int ayah) {
    // استخدام بيانات التنقل الفعلية لمصحف المدينة (604 صفحة)
    // عبر الدالة الثابتة في MushafNavigationProvider بدلاً من القيم التقريبية
    return MushafNavigationProvider.pageForSurahAyah(surah, ayah) ?? 1;
  }

  void startRecording() async {
    _errorMessage = null;
    _isModelLoading = true;
    notifyListeners(); // إخبار الواجهة بأن النموذج يُحمَّل الآن
    try {
      // Pre-flight check: ensure we have microphone permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        // Try requesting permission again
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          _isModelLoading = false;
          _state = RecitationState.error;
          _errorMessage = 'لا يمكن التسجيل بدون إذن الميكروفون. يرجى منح الإذونات.';
          notifyListeners();
          return;
        }
      }

      final success = await _asrService.loadModel();
      _isModelLoading = false;

      if (!success) {
        _state = RecitationState.error;
        _errorMessage = 'فشل تحميل نموذج الذكاء الاصطناعي. تأكد من اكتمال النماذج.';
        notifyListeners();
        return;
      }
      
      final path = await _audioRecorder.startRecording();
      if (path != null) {
        _state = RecitationState.recording;
        _isRecording = true;
        _recordingDurationMs = 0;
        _currentTranscript = 'جارٍ الاستماع...';
        _startLiveAnalysisLoop();
      } else {
        _state = RecitationState.error;
        _errorMessage = 'فشل بدء الميكروفون. تأكد من الصلاحيات والإعدادات.';
      }
    } catch (e) {
      _isModelLoading = false;
      // أمان إضافي: إذا فشل loadModel، نحاول تفريغ أي موارد متبقية
      try {
        _asrService.dispose();
      } catch (_) {}
      _state = RecitationState.error;
      _errorMessage = 'خطأ تقني: ${e.toString()}';
      debugPrint('❌ startRecording crashed with: $e');
    }
    notifyListeners();
  }

  void _startLiveAnalysisLoop() {
    _liveAnalysisTimer?.cancel();
    _liveAnalysisTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      // قفل ضد التكدس: إذا كان التحليل السابق لا يزال جارياً، نتخطى هذه الدورة
      if (!_isRecording || _isLiveAnalyzing) {
        if (!_isRecording) timer.cancel();
        return;
      }
      _isLiveAnalyzing = true;

      try {
        final partialAudio = await _audioRecorder.getPartiallyRecordedFile();
        if (partialAudio == null) return;

        // تجاوز الملفات الصغيرة جداً (بدون كلام ذي معنى) لتقليل ضغط الذاكرة
        final String partialAudioPath = partialAudio;
        final fileSize = await File(partialAudioPath).length();
        if (fileSize < 8192) {
          debugPrint('⏭ مقطع قصير جداً ($fileSize B) — تخطي التحليل');
          return;
        }

        final result = await _asrService.transcribe(partialAudioPath);
        if (result.fullText.isEmpty) return;

        _currentTranscript = result.fullText;

        // مطابقة لحظية لتحديد الآية الحالية
        final match = await _matchingService.matchTranscript(
          asrWords: result.words,
          quranText: _quranTextCache,
          hintSurah: _selectedSurah ?? _matchedSurah,
        );

        if (match.matchedWords.isNotEmpty) {
          if (match.endAyah != _matchedAyah) {
            _matchedAyahsCount++;
          }

          _matchedSurah = match.surahNumber;
          _matchedAyah = match.endAyah;
          _lastMatchedWordIndex = match.matchedWords.last.wordIndex;

          // تحديث تلوين الكلمات اللحظي (تقييم التجويد مؤجل للتحليل النهائي)
          for (int i = 0; i < match.matchedWords.length; i++) {
            final mw = match.matchedWords[i];
            final key = "${mw.surahNumber}_${mw.ayahNumber}_${mw.wordIndex + 1}";
            final verdict = mw.similarity > 0.6 ? WordVerdict.correct : WordVerdict.incorrect;
            if (verdict == WordVerdict.incorrect) _mistakesCount++;
            _liveWordVerdicts[key] = verdict;
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Partial ASR Error: $e');
      } finally {
        _isLiveAnalyzing = false; // فك القفل دائماً (حتى عند الخطأ)
      }
    });
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pauseRecording();
    _isPaused = true;
    _liveAnalysisTimer?.cancel();
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resumeRecording();
    _isPaused = false;
    _startLiveAnalysisLoop();
    notifyListeners();
  }

  void updateRecordingDuration(int ms) {
    _recordingDurationMs = ms;
    notifyListeners();
  }

  Future<void> _prepareAllQuranText() async {
    final result = await _quranRepository.getAllAyahs();
    result.fold(
      (failure) => debugPrint('Error loading all ayahs for matching: $failure'),
      (ayahs) {
        for (var a in ayahs) {
          if (!_quranTextCache.containsKey(a.surahNumber)) {
            _quranTextCache[a.surahNumber] = {};
          }
          _quranTextCache[a.surahNumber]![a.ayahNumber] = a.text;
        }
      }
    );
  }

  void stopRecording() async {
    _isRecording = false;
    _liveAnalysisTimer?.cancel();
    _state = RecitationState.analyzing;
    _analysisStep = 'جاري التحليل النهائي...';
    _analysisProgress = 0.1;
    notifyListeners();
    
    final audioPath = await _audioRecorder.stopRecording();
    if (audioPath == null) {
      _state = RecitationState.setup;
      notifyListeners();
      return;
    }

    try {
      _analysisStep = 'استخراج الكلمات باستخدام NPU...';
      _analysisProgress = 0.4;
      notifyListeners();

      final asrResult = await _asrService.transcribe(audioPath);
      
      _analysisStep = 'المطابقة مع المصحف...';
      _analysisProgress = 0.7;
      notifyListeners();

      if (_mode == RecitationMode.selected && _selectedSurah != null && !_quranTextCache.containsKey(_selectedSurah)) {
        await _prepareQuranText(_selectedSurah!);
      } else if (_mode == RecitationMode.free && _quranTextCache.isEmpty) {
        await _prepareAllQuranText();
      }

      final matchResult = await _matchingService.matchTranscript(
        asrWords: asrResult.words,
        quranText: _quranTextCache,
        hintSurah: _selectedSurah,
        hintStartAyah: _mode == RecitationMode.selected ? _startAyah : null,
        hintEndAyah: _mode == RecitationMode.selected ? _endAyah : null,
      );

      await _finishAnalysis(matchResult, asrResult.fullText, audioPath);
    } catch (e) {
      debugPrint('Final ASR Error: $e');
      _errorMessage = 'تعذر تحليل الصوت: تأكد من تسجيل صوت واضح أو جرب على هاتف حقيقي (${e.toString()})';
      _state = RecitationState.setup;
      notifyListeners();
    }
  }

  /// تحميل نتيجة تجريبية لمعاينة واجهة التقرير وتلوين الكلمات على المحاكي
  Future<void> loadDemoResult() async {
    _selectedSurah = 1;
    _selectedSurahName = 'الفاتحة';
    _startAyah = 1;
    _endAyah = 3;
    _recordingDurationMs = 12000;

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

  Future<void> _finishAnalysis(MatchResult matchResult, String rawTranscript, String? audioPath) async {
    _analysisStep = 'إعداد النتائج...';
    _analysisProgress = 0.9;
    notifyListeners();

    // حل اسم السورة المفقود في الوضع الحر
    String resolvedSurahName = _selectedSurahName;
    if (resolvedSurahName.isEmpty) {
      final surahRes = await _quranRepository.getSurahByNumber(matchResult.surahNumber);
      surahRes.fold(
        (l) => resolvedSurahName = 'غير محدد',
        (surah) => resolvedSurahName = surah?.nameArabic ?? 'غير محدد',
      );
    }

    final words = matchResult.matchedWords.map((mw) {
      return WordResult(
        spokenWord: mw.spokenWord,
        expectedWord: mw.expectedWord,
        surahNumber: mw.surahNumber,
        ayahNumber: mw.ayahNumber,
        wordIndex: mw.wordIndex,
        verdict: mw.verdict,
        confidence: mw.similarity,
        startTimeMs: mw.startMs,
        endTimeMs: mw.endMs,
      );
    }).toList();

    _currentResult = RecitationResult(
      words: words,
      surahNumber: matchResult.surahNumber,
      surahName: resolvedSurahName,
      startAyah: matchResult.startAyah,
      endAyah: matchResult.endAyah,
      durationMs: _recordingDurationMs,
      rawTranscript: rawTranscript,
      audioPath: audioPath,
    );

    // تحديث تلوين الكلمات النهائي
    _liveWordVerdicts.clear();
    for (var w in words) {
      final key = "${w.surahNumber}_${w.ayahNumber}_${w.wordIndex + 1}";
      _liveWordVerdicts[key] = w.verdict;
    }

    final session = RecitationSession()
      ..surahNumber = _currentResult!.surahNumber
      ..surahName = _currentResult!.surahName
      ..startAyah = _currentResult!.startAyah
      ..endAyah = _currentResult!.endAyah
      ..mode = _mode == RecitationMode.free ? 'free' : 'selected'
      ..accuracyPercent = _currentResult!.accuracyPercent
      ..totalWords = _currentResult!.totalWords
      ..correctWords = _currentResult!.correctWords
      ..durationSeconds = (_recordingDurationMs / 1000).round()
      ..overallGrade = _currentResult!.overallGrade
      ..rawTranscript = _currentResult!.rawTranscript
      ..resultJson = jsonEncode(_currentResult!.toJson())
      ..createdAt = DateTime.now();

    await saveSession(session);

    _state = RecitationState.result;
    notifyListeners();
  }

  void cancelRecording() async {
    _isRecording = false;
    _liveAnalysisTimer?.cancel();
    await _audioRecorder.stopRecording();
    _promptWord = null;
    _promptTimer?.cancel();
    _liveWordVerdicts.clear();
    _state = RecitationState.setup;
    notifyListeners();
  }

  /// بدء التسميع مباشرة من المينيبار (دون المرور بشاشة الإعداد)
  Future<String?> startRecitationFromMinibar() async {
    if (_isInitializingRecording) return null;
    _isInitializingRecording = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isAsrModelDownloaded) {
        _errorMessage = 'النماذج غير محملة. يرجى التوجه لمركز التحميلات.';
        return null;
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _errorMessage = 'لا يمكن البدء بدون صلاحية الميكروفون.';
        return null;
      }

      _matchedAyahsCount = 0;
      _mistakesCount = 0;
      _liveWordVerdicts.clear();
      _lastMatchedWordIndex = -1;
      _promptWord = null;
      _promptTimer?.cancel();
      _currentPage = 1;
      notifyListeners();

      // تحميل النموذج وبدء التسجيل
      final success = await _asrService.loadModel();
      if (!success) {
        _errorMessage = 'فشل تحميل نموذج الذكاء الاصطناعي.';
        return null;
      }

      final path = await _audioRecorder.startRecording();
      if (path == null) {
        _errorMessage = 'فشل بدء الميكروفون.';
        return null;
      }

      _isRecording = true;
      _recordingDurationMs = 0;
      _currentTranscript = 'جارٍ الاستماع...';
      _startLiveAnalysisLoop();
      return path;
    } catch (e) {
      _asrService.dispose();
      _errorMessage = 'خطأ تقني: ${e.toString()}';
      debugPrint('❌ startRecitationFromMinibar: $e');
      return null;
    } finally {
      _isInitializingRecording = false;
      notifyListeners();
    }
  }

  void reset() {
    _state = RecitationState.setup;
    _currentResult = null;
    _promptWord = null;
    _promptTimer?.cancel();
    _liveWordVerdicts.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ميزات المساعدة والتلقين والمقارنة الصوتية والتحليلات
  // ═══════════════════════════════════════════════

  String? getNextWord() {
    int surah;
    int ayah;
    int nextWordIdx = 0;

    if (_mode == RecitationMode.selected && _selectedSurah != null) {
      surah = _selectedSurah!;
      if (_matchedSurah == surah && _matchedAyah != null) {
        ayah = _matchedAyah!;
        nextWordIdx = _lastMatchedWordIndex + 1;
      } else {
        ayah = _startAyah;
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
    if (surahMap == null) return null;
    final ayahText = surahMap[ayah];
    if (ayahText == null) return null;

    final words = ayahText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (nextWordIdx < words.length) {
      return words[nextWordIdx];
    } else {
      // الانتقال للآية التالية
      final nextAyah = ayah + 1;
      final nextAyahText = surahMap[nextAyah];
      if (nextAyahText != null) {
        final nextWords = nextAyahText.split(' ').where((w) => w.trim().isNotEmpty).toList();
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
  Future<void> playUserWordAudio(String audioPath, int wordIndex, int totalWords, int durationMs) async {
    try {
      await _localPlayer.stop();
      if (!await File(audioPath).exists()) {
        debugPrint('User recording file not found: $audioPath');
        return;
      }
      await _localPlayer.setFilePath(audioPath);
      
      if (totalWords > 0) {
        final startMs = ((wordIndex / totalWords) * durationMs).toInt();
        await _localPlayer.seek(Duration(milliseconds: startMs));
      }
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
      final url = 'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee/murattal/${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
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
    _state = RecitationState.analytics;
    notifyListeners();
  }

  // تحديد جلسة سابقة لاستعراض نتائجها
  void selectSession(RecitationSession session) {
    if (session.resultJson != null && session.resultJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(session.resultJson!);
        _currentResult = RecitationResult(
          words: (json['words'] as List<dynamic>)
              .map((w) => WordResult(
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
                  ))
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
    
    final dates = _allSessions
        .map((s) => DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
      
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
      surahAccuracies.putIfAbsent(s.surahNumber, () => []).add(s.accuracyPercent);
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
    
    hotspots.sort((a, b) => (a['accuracy'] as num).compareTo(b['accuracy'] as num));
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
  void dispose() {
    _liveAnalysisTimer?.cancel();
    _audioRecorder.dispose();
    _localPlayer.dispose();
    _sheikhPlayer.dispose();
    super.dispose();
  }
}
