// lib/core/services/recitation/zipformer_engine.dart
// ═══════════════════════════════════════════════════════════════════════════════
// محرك التعرف الصوتي اللحظي الفونيمي (Zipformer2 CTC Engine)
//
// مستلهم ومطور استناداً إلى حزمة recite_quran (v1.0.5)
// مرخصة لوجه الله تعالى (100% Free / No-Profit).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'recitation_model_downloader.dart';

class ZipformerEngine {
  static final ZipformerEngine _instance = ZipformerEngine._internal();
  factory ZipformerEngine() => _instance;
  ZipformerEngine._internal();

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// تهيئة المحرك بالأوزان المحلية وقاموس الرموز.
  Future<bool> initialize() async {
    if (_isInitialized && _recognizer != null) return true;

    try {
      final isReady = await RecitationModelDownloader.isModelReady();
      if (!isReady) {
        debugPrint('[ZipformerEngine] ملفات النموذج غير مكتملة محلياً.');
        return false;
      }

      sherpa.initBindings();

      final modelPath = await RecitationModelDownloader.getOnnxModelPath();
      final tokensPath = await RecitationModelDownloader.getTokensPath();

      if (!File(modelPath).existsSync() || !File(tokensPath).existsSync()) {
        debugPrint('[ZipformerEngine] تعذر العثور على ملفات النموذج على القرص.');
        return false;
      }

      final config = sherpa.OnlineRecognizerConfig(
        feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
        model: sherpa.OnlineModelConfig(
          zipformer2Ctc: sherpa.OnlineZipformer2CtcModelConfig(model: modelPath),
          tokens: tokensPath,
          numThreads: 2,
          modelType: 'zipformer2_ctc',
          provider: 'cpu',
          debug: kDebugMode,
        ),
        enableEndpoint: true,
        rule1MinTrailingSilence: 4.0,
        rule2MinTrailingSilence: 2.0,
        rule3MinUtteranceLength: 30.0,
      );

      _recognizer = sherpa.OnlineRecognizer(config);
      _isInitialized = true;
      debugPrint('[ZipformerEngine] تم تهيئة محرك Zipformer2-CTC بنجاح.');
      return true;
    } catch (e, stack) {
      debugPrint('[ZipformerEngine] خطأ أثناء تهيئة المحرك: $e\n$stack');
      _isInitialized = false;
      return false;
    }
  }

  /// بدء جلسة دفق صوتي جديدة.
  void startStream() {
    if (!_isInitialized || _recognizer == null) {
      throw StateError('يجب تهيئة المحرك قبل بدء الدفق الصوتي.');
    }
    _stream?.free();
    _stream = _recognizer!.createStream();
  }

  /// إرسال عينات صوتية 16kHz Float32 للمحرك.
  void acceptWaveform(Float32List samples) {
    if (_recognizer == null || _stream == null) return;

    _stream!.acceptWaveform(samples: samples, sampleRate: 16000);
    while (_recognizer!.isReady(_stream!)) {
      _recognizer!.decode(_stream!);
    }
  }

  /// إنهاء إدخال الدفق وإجراء التفكيك النهائي.
  void finishInput() {
    if (_recognizer == null || _stream == null) return;
    _stream!.inputFinished();
    while (_recognizer!.isReady(_stream!)) {
      _recognizer!.decode(_stream!);
    }
  }

  /// قراءة النتيجة الحالية للتفكيك الصوتي اللحظي.
  sherpa.OnlineRecognizerResult? getCurrentResult() {
    if (_recognizer == null || _stream == null) return null;
    return _recognizer!.getResult(_stream!);
  }

  /// التحقق من كشف الصمت أو نهاية المقطع.
  bool isEndpoint() {
    if (_recognizer == null || _stream == null) return false;
    return _recognizer!.isEndpoint(_stream!);
  }

  /// إعادة تعيين مجرى الدفق.
  void resetStream() {
    _stream?.free();
    _stream = null;
  }

  /// تفريغ موارد المحرك.
  void dispose() {
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
    _isInitialized = false;
  }
}
