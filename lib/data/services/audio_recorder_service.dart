import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// خدمة تسجيل الصوت — تسجل تلاوة المستخدم بصيغة WAV 16kHz mono
/// مُحسَّنة لتغذية نموذج Whisper ASR
class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  AudioRecorder? _recorder;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentFilePath => _currentFilePath;

  /// تهيئة المسجل
  Future<void> _ensureRecorder() async {
    _recorder ??= AudioRecorder();
  }

  /// التحقق من صلاحية الميكروفون
  Future<bool> hasPermission() async {
    await _ensureRecorder();
    return await _recorder!.hasPermission();
  }

  /// بدء التسجيل بإعدادات Whisper المثلى
  /// 16kHz sample rate, mono channel, WAV format
  Future<String?> startRecording() async {
    await _ensureRecorder();

    // التحقق من الصلاحيات
    final hasPerms = await _recorder!.hasPermission();
    if (!hasPerms) {
      debugPrint('❌ لا توجد صلاحية للميكروفون');
      return null;
    }

    // إنشاء مسار الملف في مجلد المؤقتات الآمن لتفادي الأحرف غير الإنجليزية
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentFilePath = '${dir.path}/recitation_$timestamp.wav';

    try {
      // إعدادات التسجيل المُحسَّنة لـ Whisper
      const config = RecordConfig(
        encoder: AudioEncoder.wav,        // WAV بدون ضغط
        sampleRate: 16000,                // 16kHz — معيار Whisper
        numChannels: 1,                   // Mono
        bitRate: 256000,                  // 256kbps
      );

      await _recorder!.start(config, path: _currentFilePath!);
      _isRecording = true;
      _isPaused = false;
      debugPrint('🎙 بدء التسجيل: $_currentFilePath');
      return _currentFilePath;
    } catch (e) {
      debugPrint('❌ فشل بدء التسجيل: $e');
      _currentFilePath = null;
      return null;
    }
  }

  /// إيقاف مؤقت
  Future<void> pauseRecording() async {
    if (_recorder != null && _isRecording && !_isPaused) {
      await _recorder!.pause();
      _isPaused = true;
      debugPrint('⏸ إيقاف مؤقت للتسجيل');
    }
  }

  /// استئناف
  Future<void> resumeRecording() async {
    if (_recorder != null && _isRecording && _isPaused) {
      await _recorder!.resume();
      _isPaused = false;
      debugPrint('▶️ استئناف التسجيل');
    }
  }

  /// إيقاف التسجيل وإرجاع مسار الملف
  Future<String?> stopRecording() async {
    if (!_isRecording || _recorder == null) return null;

    try {
      final path = await _recorder!.stop();
      _isRecording = false;
      _isPaused = false;
      debugPrint('⏹ إيقاف التسجيل: $path');

      // التحقق من حجم الملف
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('📁 حجم الملف: ${(size / 1024).toStringAsFixed(1)} KB');
          
          if (size < 1024) { // أقل من 1KB — تسجيل فارغ
            debugPrint('⚠️ التسجيل قصير جداً');
          }
        }
      }
      return path ?? _currentFilePath;
    } catch (e) {
      debugPrint('❌ فشل إيقاف التسجيل: $e');
      _isRecording = false;
      return _currentFilePath;
    }
  }

  /// إلغاء التسجيل وحذف الملف
  Future<void> cancelRecording() async {
    if (_recorder != null && _isRecording) {
      try {
        await _recorder!.stop();
      } catch (_) {}
    }
    _isRecording = false;

    // حذف الملف إن وجد
    if (_currentFilePath != null) {
      try {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑 حذف ملف التسجيل الملغى');
        }
      } catch (_) {}
      _currentFilePath = null;
    }
  }

  /// الحصول على شدة الصوت الحالية (للموجة الصوتية)
  Future<double> getAmplitude() async {
    if (!_isRecording || _recorder == null) return 0.0;
    try {
      final amp = await _recorder!.getAmplitude();
      // تحسين الحساسية: عادة ما يكون الصوت البشري بين -40 و -10 ديسيبل
      // سنركز النطاق ليكون أكثر تفاعلاً
      double current = amp.current;
      if (current < -60) current = -60; // ضجيج الخلفية
      
      final normalized = (current + 60) / 60;
      return normalized.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// حذف تسجيل قديم
  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('⚠️ فشل حذف الملف: $e');
    }
  }

  /// الحصول على نسخة مؤقتة من الملف الجاري تسجيله للتحليل اللحظي
  /// يصلح WAV data size فقط (بقية الهيدر ثابت من RecordConfig)
  Future<String?> getPartiallyRecordedFile() async {
    if (!_isRecording || _currentFilePath == null) return null;

    try {
      final originalFile = File(_currentFilePath!);
      if (!await originalFile.exists()) return null;

      final bytes = await originalFile.readAsBytes();
      if (bytes.length < 44) return null;

      // مكتبة record تبدأ بـ WAV header صحيح (44 بايت) ولكن data size لا يُحدث
      // حتى إغلاق الملف. نصلح فقط data size (آخر 4 بايت من الهيدر، offset 40)
      final dataSize = bytes.length - 44;
      final fileSize = dataSize + 36;

      final fixedBytes = Uint8List.fromList(bytes);
      // File size (RIFF chunk size)
      fixedBytes[4] = fileSize & 0xFF;
      fixedBytes[5] = (fileSize >> 8) & 0xFF;
      fixedBytes[6] = (fileSize >> 16) & 0xFF;
      fixedBytes[7] = (fileSize >> 24) & 0xFF;
      // Data chunk size (آخر 4 بايت في الـ WAV header)
      fixedBytes[40] = dataSize & 0xFF;
      fixedBytes[41] = (dataSize >> 8) & 0xFF;
      fixedBytes[42] = (dataSize >> 16) & 0xFF;
      fixedBytes[43] = (dataSize >> 24) & 0xFF;

      final dir = await getTemporaryDirectory();
      final tempPath = '${dir.path}/partial_recitation.wav';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(fixedBytes, flush: true);
      debugPrint('🎙 نسخة مؤقتة: ${(bytes.length / 1024).toStringAsFixed(1)} KB | عينات: ${dataSize ~/ 2}');
      return tempFile.path;
    } catch (e) {
      debugPrint('⚠️ فشل getPartiallyRecordedFile: $e');
      return null;
    }
  }

  /// التخلص من الموارد
  void dispose() {
    _recorder?.dispose();
    _recorder = null;
    _isRecording = false;
  }
}
