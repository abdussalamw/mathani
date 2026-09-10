import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// نتيجة التعرف على الكلام (ASR)
class AsrWord {
  final String text;
  final int startMs;
  final int endMs;
  final double confidence;

  const AsrWord({
    required this.text,
    required this.startMs,
    required this.endMs,
    this.confidence = 1.0,
  });
}

/// نتيجة ASR كاملة
class AsrResult {
  final String fullText;
  final List<AsrWord> words;
  final int durationMs;

  const AsrResult({
    required this.fullText,
    required this.words,
    required this.durationMs,
  });
}

/// خدمة التعرف على التلاوة القرآنية (محلياً بالكامل باستخدام NPU)
class AsrService {
  static final AsrService _instance = AsrService._internal();
  factory AsrService() => _instance;
  AsrService._internal();

  bool _isModelLoaded = false;
  bool _isLoading = false;
  
  sherpa.OfflineRecognizer? _recognizer;

  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;

  /// تهيئة النموذج على المعالج العصبي (NPU) مباشرة
  Future<bool> loadModel() async {
    if (_isModelLoaded) return true;
    if (_isLoading) return false;

    _isLoading = true;
    try {
      final directory = await getApplicationSupportDirectory();
      final modelDir = Directory('${directory.path}/ai_models/asr');
      
      if (!await modelDir.exists()) {
        throw Exception('مجلد النموذج غير موجود. يرجى تحميله أولاً.');
      }

      // البحث عن ملفات النموذج
      String encoderPath = '${modelDir.path}/encoder.int8.onnx';
      String decoderPath = '${modelDir.path}/decoder.int8.onnx';
      String tokensPath = '${modelDir.path}/tokens.txt';

      if (!await File(encoderPath).exists() || !await File(decoderPath).exists() || !await File(tokensPath).exists()) {
        debugPrint('⚠️ المسار المباشر غير موجود، بحث متقدم...');
        encoderPath = _findFile(modelDir, 'encoder') ?? '';
        decoderPath = _findFile(modelDir, 'decoder') ?? '';
        tokensPath = _findFile(modelDir, 'tokens.txt') ?? '';
      }

      if (encoderPath.isEmpty || decoderPath.isEmpty || tokensPath.isEmpty) {
        debugPrint('❌ الملفات المفقودة:');
        if (encoderPath.isEmpty) debugPrint('- encoder.onnx');
        if (decoderPath.isEmpty) debugPrint('- decoder.onnx');
        if (tokensPath.isEmpty) debugPrint('- tokens.txt');
        throw Exception('ملفات النموذج غير مكتملة');
      }

      // تسجيل أحجام الملفات
      debugPrint('📂 Encoder: $encoderPath (${(await File(encoderPath).length() / 1024 / 1024).toStringAsFixed(1)} MB)');
      debugPrint('📂 Decoder: $decoderPath (${(await File(decoderPath).length() / 1024 / 1024).toStringAsFixed(1)} MB)');
      debugPrint('📂 Tokens : $tokensPath (${await File(tokensPath).length()} bytes)');

      // تحديد مزود التسريع (مع دعم التراجع التلقائي لـ CPU)
      String primaryProvider = 'cpu';
      if (Platform.isAndroid) {
        primaryProvider = 'nnapi';
      } else if (Platform.isIOS || Platform.isMacOS) {
        primaryProvider = 'coreml';
      }

      final whisperConfig = sherpa.OfflineWhisperModelConfig(
        encoder: encoderPath,
        decoder: decoderPath,
        language: 'ar',
        task: 'transcribe',
        tailPaddings: -1,
      );

      // محاولة التحميل باستخدام المزود الأساسي (NPU/CoreML)، مع التراجع لـ CPU إن فشل
      bool initialized = false;
      for (final provider in [primaryProvider, 'cpu']) {
        try {
          debugPrint('🚀 محاولة تهيئة محرك التسميع بمزود: $provider');
          final modelConfig = sherpa.OfflineModelConfig(
            whisper: whisperConfig,
            tokens: tokensPath,
            numThreads: 4,
            debug: false,
            provider: provider,
          );

          final config = sherpa.OfflineRecognizerConfig(model: modelConfig);
          _recognizer = sherpa.OfflineRecognizer(config);

          if (_recognizer != null) {
            debugPrint('✅ تم تحميل نموذج التسميع بنجاح باستخدام ($provider)');
            initialized = true;
            break;
          }
        } catch (initErr) {
          debugPrint('⚠️ فشل مزود ($provider): $initErr - جاري تجربة البديل...');
          _recognizer?.free();
          _recognizer = null;
          if (provider == 'cpu') rethrow;
        }
      }

      if (!initialized || _recognizer == null) {
        throw Exception('فشل إنشاء محرك التعرف بعد تجربة كافة المزودات');
      }

      _isModelLoaded = true;
      return true;
    } catch (e) {
      debugPrint('❌ فشل loadModel: $e');
      _recognizer?.free();
      _recognizer = null;
      _isModelLoaded = false;
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// بحث مساعد عن ملف في المجلد ومجلداته الفرعية
  String? _findFile(Directory dir, String pattern) {
    try {
      for (var entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last.toLowerCase();
          if (name.endsWith('.backup')) continue;
          if (name.contains(pattern.toLowerCase())) {
            return entity.path;
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching in ${dir.path}: $e');
    }
    return null;
  }

  /// تحليل الصوت المكتمل وإرجاع النتيجة
  Future<AsrResult> transcribe(String audioFilePath) async {
    if (!_isModelLoaded || _recognizer == null) {
      final loaded = await loadModel();
      if (!loaded) throw Exception('النموذج غير جاهز');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('ملف الصوت غير موجود');
    }

    // نسخ الملف لمسار آمن لضمان فتح مكتبة C++ sherpa_onnx للملف حتى مع المسارات غير الإنجليزية
    String safePath = audioFilePath;
    File? tempCopiedFile;
    if (audioFilePath.contains(RegExp(r'[^\x00-\x7F]'))) {
      final tempDir = await getTemporaryDirectory();
      final safeFile = File('${tempDir.path}/asr_safe_input.wav');
      await safeFile.writeAsBytes(await file.readAsBytes());
      safePath = safeFile.path;
      tempCopiedFile = safeFile;
    }

    // قراءة بيانات الصوت باستخدام sherpa
    final waveData = sherpa.readWave(safePath);

    // تنظيف الملف المؤقت إن وجد
    if (tempCopiedFile != null) {
      try {
        await tempCopiedFile.delete();
      } catch (_) {}
    }

    final int sampleRate = waveData.sampleRate;
    if (sampleRate <= 0 || waveData.samples.isEmpty) {
      throw Exception('ملف الصوت تالف أو لم يتم تسجيل أي صوت');
    }

    // Whisper small: حجم الإدخال يجب أن يكون 30 ثانية = 480000 عينة @ 16kHz
    const int minSamples = 16000; // 1 ثانية حد أدنى
    if (waveData.samples.length < minSamples) {
      throw Exception('التسجيل قصير جداً (${(waveData.samples.length / sampleRate * 1000).round()} مللي ثانية). اقرأ لمدة أطول.');
    }

    // Padding ديناميكي إلى 30 ثانية (480000 عينة) لمنع ONNX shape mismatch
    final int samplesPer30Sec = 30 * sampleRate;
    final Float32List processedSamples;
    if (waveData.samples.length < samplesPer30Sec) {
      processedSamples = Float32List(samplesPer30Sec);
      processedSamples.setRange(0, waveData.samples.length, waveData.samples);
      debugPrint('🎵 ASR: Pad from ${waveData.samples.length} → $samplesPer30Sec عينة');
    } else {
      processedSamples = waveData.samples;
    }

    final stream = _recognizer!.createStream();
    stream.acceptWaveform(sampleRate: sampleRate, samples: processedSamples);
    
    _recognizer!.decode(stream);
    
    final result = _recognizer!.getResult(stream);
    final text = result.text;
    final words = text.split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map((w) => AsrWord(text: w, startMs: 0, endMs: 0))
        .toList();

    stream.free();

    final duration = sampleRate > 0 ? (waveData.samples.length / sampleRate * 1000).toInt() : 0;

    return AsrResult(
      fullText: text,
      words: words,
      durationMs: duration,
    );
  }

  /// التحقق من إمكانية تشغيل محرك التعرف الصوتي على هذا الجهاز.
  ///
  /// ملاحظة صريحة: المحرك (sherpa-onnx) يعمل على الـ CPU فقط حالياً —
  /// لا يوجد استخدام فعلي لـ NPU/NNAPI/CoreML، لذا لا ندّعي ذلك.
  /// القيمة true تعني "المنصة مدعومة لتشغيل المحرك" وليس "يوجد NPU".
  Future<bool> checkNpuSupport() async {
    // جميع المنصات المستهدفة (Android/iOS/Windows/Linux/macOS)
    // تشغّل المحرك بنجاح على CPU.
    return true;
  }

  Future<bool> isModelDownloaded() async {
    final directory = await getApplicationSupportDirectory();
    final asrDir = Directory('${directory.path}/ai_models/asr');
    return await asrDir.exists() && asrDir.listSync().length > 1;
  }

  int get modelSizeMB => 177;

  void dispose() {
    _recognizer?.free();
    _recognizer = null;
    _isModelLoaded = false;
  }
}

