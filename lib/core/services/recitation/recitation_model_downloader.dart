// lib/core/services/recitation/recitation_model_downloader.dart
// ═══════════════════════════════════════════════════════════════════════════════
// خدمة تنزيل والتحقق من ملفات محرك التسميع الذكي (Zipformer CTC)
//
// تعتمد نمط التحميل المتدفق مع شريط التقدم، وتحفظ الملفات محلياً.
// بعد اكتمال التحميل يعمل المحرك 100% دون أي اتصال شبكي (Offline).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RecitationModelDownloader {
  static const String modelBaseUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/';

  static const String onnxFileName = 'zipformer_p_arabic_v3.int8.onnx';
  static const String phonemesFileName = 'ordered_quran_phonemes.json';
  static const String tokensFileName = 'tokens.txt';

  static const int minOnnxSizeBytes = 60 * 1024 * 1024; // > 60 MB
  static const int minPhonemesSizeBytes = 10 * 1024 * 1024; // > 10 MB

  /// المسار المحلي لمجلد ملفات التسميع.
  static Future<Directory> getModelDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory('${baseDir.path}/recitation_models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// التحقق من جاهزية ملفات النموذج والبيانات محلياً.
  static Future<bool> isModelReady() async {
    try {
      final dir = await getModelDirectory();
      final onnxFile = File('${dir.path}/$onnxFileName');
      final phonemesFile = File('${dir.path}/$phonemesFileName');

      if (!await onnxFile.exists() || !await phonemesFile.exists()) {
        return false;
      }

      final onnxLen = await onnxFile.length();
      final phonemesLen = await phonemesFile.length();

      return onnxLen >= minOnnxSizeBytes && phonemesLen >= minPhonemesSizeBytes;
    } catch (_) {
      return false;
    }
  }

  /// استخراج ملف tokens.txt من أصول التطبيق إلى مجلد النماذج إن لم يكن موجوداً.
  static Future<File> ensureTokensExtracted() async {
    final dir = await getModelDirectory();
    final targetFile = File('${dir.path}/$tokensFileName');

    if (!await targetFile.exists() || await targetFile.length() < 100) {
      final byteData = await rootBundle.load('assets/data/tokens.txt');
      final buffer = byteData.buffer;
      await targetFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    }
    return targetFile;
  }

  /// تنزيل النموذج وبيانات الفونيمات مع متابعة التقدم.
  static Future<void> downloadRequiredFiles({
    required void Function(double progress, String statusText) onProgress,
  }) async {
    final dir = await getModelDirectory();

    // 1. تنزيل نموذج ONNX (حوالي 69.3 MB)
    final onnxFile = File('${dir.path}/$onnxFileName');
    if (!await onnxFile.exists() || await onnxFile.length() < minOnnxSizeBytes) {
      onProgress(0.05, 'بدء تنزيل نموذج التعرف الصوتي...');
      await _downloadStreamingFile(
        url: '$modelBaseUrl$onnxFileName',
        targetFile: onnxFile,
        onFileProgress: (fileProgress) {
          // ONNX يمثل 0% إلى 80% من إجمالي العملية
          onProgress(fileProgress * 0.80, 'جاري تنزيل نموذج التعرف الصوتي (${(fileProgress * 100).toInt()}%)...');
        },
      );
    }

    // 2. تنزيل قاموس الآيات الفونيمي (حوالي 12.2 MB)
    final phonemesFile = File('${dir.path}/$phonemesFileName');
    if (!await phonemesFile.exists() || await phonemesFile.length() < minPhonemesSizeBytes) {
      onProgress(0.82, 'بدء تنزيل القاموس الفونيمي للقرآن الكريم...');
      await _downloadStreamingFile(
        url: '$modelBaseUrl$phonemesFileName',
        targetFile: phonemesFile,
        onFileProgress: (fileProgress) {
          // JSON يمثل 80% إلى 98% من إجمالي العملية
          final totalProgress = 0.80 + (fileProgress * 0.18);
          onProgress(totalProgress, 'جاري تنزيل قاموس الآيات الصوتي (${(fileProgress * 100).toInt()}%)...');
        },
      );
    }

    // 3. ضمان وجود tokens.txt
    onProgress(0.99, 'تهيئة الرموز الصوتية...');
    await ensureTokensExtracted();

    onProgress(1.0, 'اكتمل تجهيز محرك التسميع بنجاح.');
  }

  /// تنزيل ملف متدفق وتخزينه مباشرة على القرص.
  static Future<void> _downloadStreamingFile({
    required String url,
    required File targetFile,
    required void Function(double progress) onFileProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
          'فشل التنزيل برمز استجابة: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      // كتابة تدفقية لتفادي استهلاك الذاكرة (OOM)
      final tempFile = File('${targetFile.path}.tmp');
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onFileProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // استبدال الملف المؤقت بالملف النهائي بعد التحقق
      if (await tempFile.length() > 0) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);
      } else {
        throw Exception('الملف الذي تم تنزيله فارغ.');
      }
    } finally {
      client.close();
    }
  }

  /// مسار ملف النموذج.
  static Future<String> getOnnxModelPath() async {
    final dir = await getModelDirectory();
    return '${dir.path}/$onnxFileName';
  }

  /// مسار ملف الفونيمات.
  static Future<String> getPhonemesJsonPath() async {
    final dir = await getModelDirectory();
    return '${dir.path}/$phonemesFileName';
  }

  /// مسار ملف tokens.txt.
  static Future<String> getTokensPath() async {
    final file = await ensureTokensExtracted();
    return file.path;
  }
}
