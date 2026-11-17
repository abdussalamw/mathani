import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

/// نتيجة فحص واحد
class DiagnosticCheckResult {
  final String name;
  final bool passed;
  final String detail;
  final String? errorMessage;
  final Duration? duration;

  const DiagnosticCheckResult({
    required this.name,
    required this.passed,
    required this.detail,
    this.errorMessage,
    this.duration,
  });

  String get icon => passed ? '✅' : '❌';
}

/// تقرير التشخيص الكامل
class DiagnosticReport {
  final List<DiagnosticCheckResult> checks;
  final DateTime timestamp;

  const DiagnosticReport({required this.checks, required this.timestamp});

  bool get allPassed => checks.every((c) => c.passed);
  int get passedCount => checks.where((c) => c.passed).length;

  String toText() {
    final sb = StringBuffer();
    sb.writeln('═══════════════════════════════');
    sb.writeln('تقرير تشخيص نظام التسميع');
    sb.writeln(timestamp.toIso8601String());
    sb.writeln('═══════════════════════════════');
    for (final c in checks) {
      sb.writeln('${c.icon} ${c.name}');
      sb.writeln('   ${c.detail}');
      if (c.errorMessage != null) sb.writeln('   ⚠️ ${c.errorMessage}');
      if (c.duration != null) {
        sb.writeln('   ⏱ ${c.duration!.inMilliseconds}ms');
      }
      sb.writeln();
    }
    sb.writeln('النتيجة: $passedCount/${checks.length} اجتازت');
    return sb.toString();
  }
}

/// خدمة التشخيص الشامل لنظام التسميع
class RecitationDiagnosticService {
  static final RecitationDiagnosticService _instance =
      RecitationDiagnosticService._internal();
  factory RecitationDiagnosticService() => _instance;
  RecitationDiagnosticService._internal();

  static const String _asrModelZipUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tadabur-whisper-mobile.zip';
  static const String _tajweedModelUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/tajweed_classifier.tflite';

  /// تشغيل التشخيص الكامل
  Future<DiagnosticReport> runAll({
    void Function(String checkName)? onCheckStarted,
  }) async {
    final checks = <DiagnosticCheckResult>[];

    // الفحص 1: الميكروفون والصلاحيات
    onCheckStarted?.call('الميكروفون');
    checks.add(await _checkMicrophone());

    // الفحص 2: ملفات نموذج تدبر
    onCheckStarted?.call('ملفات النموذج');
    checks.add(await _checkModelFiles());

    // الفحص 3: تهيئة Sherpa ONNX
    onCheckStarted?.call('محرك Sherpa ONNX');
    checks.add(await _checkSherpaInit());

    // الفحص 4: التسجيل وقراءة WAV
    onCheckStarted?.call('التسجيل الصوتي');
    checks.add(await _checkRecording());

    // الفحص 5: URL نموذج تدبر
    onCheckStarted?.call('رابط نموذج تدبر');
    checks.add(await _checkModelUrl());

    // الفحص 6: ملف التجويد المحلي والرابط
    onCheckStarted?.call('نموذج التجويد');
    checks.add(await _checkTajweedModel());

    // الفحص 7: منصة التشغيل
    onCheckStarted?.call('منصة التشغيل');
    checks.add(_checkPlatform());

    return DiagnosticReport(checks: checks, timestamp: DateTime.now());
  }

  // ─────────────────────────────────────────────
  // الفحص 1: الميكروفون
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkMicrophone() async {
    try {
      final recorder = AudioRecorder();
      final hasPermission = await recorder.hasPermission();
      await recorder.dispose();
      if (hasPermission) {
        return const DiagnosticCheckResult(
          name: 'الميكروفون',
          passed: true,
          detail: 'الصلاحية ممنوحة ✓',
        );
      } else {
        return const DiagnosticCheckResult(
          name: 'الميكروفون',
          passed: false,
          detail: 'الصلاحية غير ممنوحة',
          errorMessage: 'اذهب للإعدادات وامنح صلاحية الميكروفون',
        );
      }
    } catch (e) {
      return DiagnosticCheckResult(
        name: 'الميكروفون',
        passed: false,
        detail: 'خطأ في الوصول للميكروفون',
        errorMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 2: ملفات نموذج تدبر
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkModelFiles() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final asrDir = Directory('${directory.path}/ai_models/asr');

      if (!await asrDir.exists()) {
        return DiagnosticCheckResult(
          name: 'ملفات نموذج تدبر',
          passed: false,
          detail: 'المجلد غير موجود: ${asrDir.path}',
          errorMessage: 'يجب تحميل النموذج أولاً',
        );
      }

      final files = await asrDir.list(recursive: true).toList();
      final fileDetails = <String>[];
      bool hasEncoder = false, hasDecoder = false, hasTokens = false;
      double totalMB = 0;

      for (final f in files) {
        if (f is File) {
          final name = f.path.split(Platform.pathSeparator).last;
          if (name.endsWith('.backup')) continue; // تجاهل النسخ الاحتياطية
          final sz = await f.length();
          final mb = sz / 1024 / 1024;
          totalMB += mb;
          fileDetails.add('$name: ${mb.toStringAsFixed(2)} MB');
          if (name.contains('encoder') && mb > 1) hasEncoder = true;
          if (name.contains('decoder') && mb > 1) hasDecoder = true;
          if (name.contains('tokens') && sz > 100) hasTokens = true;
        }
      }

      final allPresent = hasEncoder && hasDecoder && hasTokens;
      final detail = [
        'المجموع: ${totalMB.toStringAsFixed(1)} MB',
        'Encoder: ${hasEncoder ? "✓" : "✗"}',
        'Decoder: ${hasDecoder ? "✓" : "✗"}',
        'Tokens: ${hasTokens ? "✓" : "✗"}',
        ...fileDetails,
      ].join('\n   ');

      return DiagnosticCheckResult(
        name: 'ملفات نموذج تدبر',
        passed: allPresent,
        detail: detail,
        errorMessage: allPresent ? null : 'ملفات ناقصة — أعد تحميل النموذج',
      );
    } catch (e) {
      return DiagnosticCheckResult(
        name: 'ملفات نموذج تدبر',
        passed: false,
        detail: 'خطأ في قراءة الملفات',
        errorMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 3: تهيئة Sherpa ONNX — تحقق من المسارات فقط (لا ننشئ recognizer حقيقي لتجنب crash)
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkSherpaInit() async {
    final stopwatch = Stopwatch()..start();
    try {
      final directory = await getApplicationSupportDirectory();
      final asrDir = Directory('${directory.path}/ai_models/asr');
      if (!await asrDir.exists()) {
        return const DiagnosticCheckResult(
          name: 'محرك Sherpa ONNX',
          passed: false,
          detail: 'تعذر الفحص — ملفات النموذج غير موجودة',
        );
      }

      // البحث عن المسارات (تتجاهل النسخ الاحتياطية .backup)
      String encoderPath = '', decoderPath = '', tokensPath = '';
      await for (final f in asrDir.list(recursive: true)) {
        if (f is File) {
          final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
          if (name.endsWith('.backup')) continue; // تجاهل النسخ الاحتياطية
          if (name.contains('encoder') && name.endsWith('.onnx')) {
            encoderPath = f.path;
          } else if (name.contains('decoder') && name.endsWith('.onnx')) {
            decoderPath = f.path;
          } else if (name.contains('tokens')) {
            tokensPath = f.path;
          }
        }
      }

      if (encoderPath.isEmpty || decoderPath.isEmpty || tokensPath.isEmpty) {
        return const DiagnosticCheckResult(
          name: 'محرك Sherpa ONNX',
          passed: false,
          detail: 'مسارات الملفات غير مكتملة',
          errorMessage: 'Encoder أو Decoder أو Tokens مفقود',
        );
      }

      // التحقق من أحجام الملفات (دون إنشاء recognizer فعلي)
      final encoderSize = await File(encoderPath).length();
      final decoderSize = await File(decoderPath).length();
      final tokensSize = await File(tokensPath).length();

      final sizesOk =
          encoderSize > 1024 * 1024 && // > 1MB
          decoderSize > 1024 * 1024 && // > 1MB
          tokensSize > 100; // > 100 bytes

      String provider = 'nnapi';
      if (Platform.isWindows) provider = 'directml';
      if (Platform.isIOS || Platform.isMacOS) provider = 'coreml';

      stopwatch.stop();

      return DiagnosticCheckResult(
        name: 'محرك Sherpa ONNX',
        passed: sizesOk,
        detail: [
          'Encoder: $encoderPath',
          '  ↳ ${(encoderSize / 1024 / 1024).toStringAsFixed(1)} MB',
          'Decoder: $decoderPath',
          '  ↳ ${(decoderSize / 1024 / 1024).toStringAsFixed(1)} MB',
          'Tokens : $tokensPath',
          '  ↳ ${(tokensSize / 1024).toStringAsFixed(1)} KB',
          'المسرّع المستهدف: $provider',
          '⚠️ تم تخطي إنشاء Recognizer (فحص مسارات فقط لتجنب تعارض الموارد)',
        ].join('\n   '),
        errorMessage: sizesOk
            ? null
            : 'أحد الملفات صغير جداً أو تالف — أعد تحميل النموذج',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return DiagnosticCheckResult(
        name: 'محرك Sherpa ONNX',
        passed: false,
        detail: 'استثناء غير متوقع',
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 4: التسجيل وقراءة WAV
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkRecording() async {
    if (kIsWeb) {
      return const DiagnosticCheckResult(
        name: 'التسجيل الصوتي',
        passed: false,
        detail: 'غير مدعوم على الويب',
      );
    }
    try {
      final recorder = AudioRecorder();
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        await recorder.dispose();
        return const DiagnosticCheckResult(
          name: 'التسجيل الصوتي',
          passed: false,
          detail: 'لا توجد صلاحية للميكروفون',
        );
      }

      final dir = await getTemporaryDirectory();
      final testPath = '${dir.path}/diag_test.wav';

      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: testPath,
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();
      await recorder.dispose();

      final file = File(testPath);
      if (!await file.exists()) {
        return const DiagnosticCheckResult(
          name: 'التسجيل الصوتي',
          passed: false,
          detail: 'ملف WAV لم يُنشأ بعد التسجيل',
        );
      }

      final bytes = await file.readAsBytes();
      final fileSizeKB = (bytes.length / 1024).toStringAsFixed(1);

      // التحقق من WAV header
      if (bytes.length < 44) {
        return DiagnosticCheckResult(
          name: 'التسجيل الصوتي',
          passed: false,
          detail: 'ملف WAV صغير جداً ($fileSizeKB KB) — header ناقص',
        );
      }

      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final wave = String.fromCharCodes(bytes.sublist(8, 12));
      final headerOk = riff == 'RIFF' && wave == 'WAVE';

      // إيجاد data chunk
      int dataOffset = -1;
      for (int i = 12; i < bytes.length - 8; i++) {
        if (bytes[i] == 0x64 &&
            bytes[i + 1] == 0x61 &&
            bytes[i + 2] == 0x74 &&
            bytes[i + 3] == 0x61) {
          dataOffset = i;
          break;
        }
      }

      await file.delete();

      return DiagnosticCheckResult(
        name: 'التسجيل الصوتي',
        passed: headerOk && dataOffset != -1,
        detail: [
          'حجم الملف: $fileSizeKB KB',
          'RIFF header: ${headerOk ? "✓" : "✗"} ($riff/$wave)',
          'data chunk: ${dataOffset != -1 ? "✓ offset=$dataOffset" : "✗ غير موجود"}',
        ].join('\n   '),
      );
    } catch (e) {
      return DiagnosticCheckResult(
        name: 'التسجيل الصوتي',
        passed: false,
        detail: 'استثناء أثناء التسجيل',
        errorMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 5: إمكانية الوصول لرابط النموذج
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkModelUrl() async {
    try {
      final response = await http
          .head(Uri.parse(_asrModelZipUrl))
          .timeout(const Duration(seconds: 10));
      final ok = response.statusCode == 200 || response.statusCode == 302;
      return DiagnosticCheckResult(
        name: 'رابط نموذج تدبر',
        passed: ok,
        detail:
            'HTTP ${response.statusCode} — ${ok ? "الرابط يعمل" : "الرابط معطوب"}',
        errorMessage: ok ? null : 'تحقق من روابط GitHub Release',
      );
    } catch (e) {
      return DiagnosticCheckResult(
        name: 'رابط نموذج تدبر',
        passed: false,
        detail: 'تعذر الاتصال بالرابط',
        errorMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 6: نموذج التجويد
  // ─────────────────────────────────────────────
  Future<DiagnosticCheckResult> _checkTajweedModel() async {
    final details = <String>[];
    bool localFileExists = false;

    // فحص الرابط
    try {
      final response = await http
          .head(Uri.parse(_tajweedModelUrl))
          .timeout(const Duration(seconds: 8));
      final urlOk = response.statusCode == 200 || response.statusCode == 302;
      details.add(
        'رابط GitHub: HTTP ${response.statusCode} ${urlOk ? "✓" : "✗ (404)"}',
      );
    } catch (e) {
      details.add('رابط GitHub: تعذر الاتصال');
    }

    // فحص الملف المحلي
    try {
      final directory = await getApplicationSupportDirectory();
      final tajweedDir = Directory('${directory.path}/ai_models/tajweed');
      if (await tajweedDir.exists()) {
        final files = await tajweedDir.list(recursive: true).toList();
        for (final f in files) {
          if (f is File && f.path.endsWith('.tflite')) {
            final sz = await f.length();
            details.add(
              'ملف محلي: ${f.path.split(Platform.pathSeparator).last} (${(sz / 1024).toStringAsFixed(0)} KB)',
            );
            localFileExists = true;
          }
        }
        if (!localFileExists) details.add('ملف محلي: غير موجود');
      } else {
        details.add('مجلد التجويد: غير موجود');
      }
    } catch (e) {
      details.add('خطأ في فحص الملف المحلي: $e');
    }

    details.add(
      'ملاحظة: نموذج التجويد يعمل بمحاكاة (Mock Data) للتطوير البصري وسيربط بـ TFLite لاحقاً.',
    );

    if (localFileExists) {
      return DiagnosticCheckResult(
        name: 'نموذج التجويد (tflite)',
        passed: true,
        detail:
            '${details.join('\n   ')}\n   [حالة الملف]: متوفر محلياً وجاهز (تم إنشاء ملف placeholder للتوافق)',
      );
    } else {
      return DiagnosticCheckResult(
        name: 'نموذج التجويد (tflite)',
        passed: false,
        detail: details.join('\n   '),
        errorMessage: 'الملف المحلي مفقود. يرجى الضغط على زر تحميل نموذج التجويد في مركز التحميل ليتم كتابة ملف placeholder متوافق تلقائياً.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // الفحص 7: منصة التشغيل
  // ─────────────────────────────────────────────
  DiagnosticCheckResult _checkPlatform() {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    String provider = 'غير محدد';
    String npuNote = '';

    if (Platform.isAndroid) {
      provider = 'nnapi';
      npuNote = 'يتطلب API 28+ و ARM64';
    } else if (Platform.isIOS || Platform.isMacOS) {
      provider = 'coreml';
      npuNote = 'Apple Neural Engine';
    } else if (Platform.isWindows) {
      provider = 'directml';
      npuNote = 'DirectML GPU/NPU';
    }

    return DiagnosticCheckResult(
      name: 'منصة التشغيل',
      passed: true,
      detail: [
        'المنصة: $platform',
        'الإصدار: $version',
        'المسرّع المستخدم: $provider',
        'ملاحظة NPU: $npuNote',
      ].join('\n   '),
    );
  }
}
