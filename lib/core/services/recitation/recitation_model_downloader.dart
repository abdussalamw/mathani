import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'zipformer_npu_package.dart';

class RecitationModelDownloader {
  static const String modelBaseUrl =
      'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/';
  static const String _testBaseUrl = String.fromEnvironment(
    'MATHANI_ZIPFORMER_NPU_TEST_BASE_URL',
  );
  static const String _downloadBaseUrl = _testBaseUrl == ''
      ? modelBaseUrl
      : _testBaseUrl;

  static const String onnxFileName = 'zipformer_p_arabic_v3.int8.onnx';
  static const String phonemesFileName = 'ordered_quran_phonemes.json';
  static const String tokensFileName = 'tokens.txt';

  static const _downloadFiles = [
    (ZipformerNpuPackage.binary, 'نموذج Zipformer المجهّز لـNPU'),
    (ZipformerNpuPackage.phonemes, 'مرجع الفونيمات'),
  ];
  static const _networkTimeout = Duration(seconds: 30);

  static Future<Directory> getModelDirectory({bool create = true}) async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory('${baseDir.path}/recitation_models');
    if (create && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<bool> isModelReady() async {
    try {
      final dir = await getModelDirectory(create: false);
      if (!await dir.exists()) return false;
      final binaryFile = File('${dir.path}/${ZipformerNpuPackage.binary.name}');
      if (!await binaryFile.exists()) return false;
      await ensureContextModelExtracted();
      return await compute(_verifyNpuFiles, dir.path);
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> readBundledContextModel() async {
    final byteData = await rootBundle.load(
      'assets/data/${ZipformerNpuPackage.context.name}',
    );
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != ZipformerNpuPackage.context.sha256) {
      throw const FormatException('Invalid bundled Zipformer context model');
    }
    return bytes;
  }

  static Future<File> ensureContextModelExtracted() async {
    final dir = await getModelDirectory();
    final target = File('${dir.path}/${ZipformerNpuPackage.context.name}');
    if (!await ZipformerNpuPackage.matches(
      target,
      ZipformerNpuPackage.context,
    )) {
      final temporary = File('${target.path}.tmp');
      await temporary.writeAsBytes(await readBundledContextModel(), flush: true);
      await temporary.rename(target.path);
    }
    return target;
  }

  static Future<Uint8List> readBundledTokens() async {
    final byteData = await rootBundle.load('assets/data/tokens.txt');
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != ZipformerNpuPackage.tokens.sha256) {
      throw const FormatException('Invalid bundled Zipformer vocabulary');
    }
    return bytes;
  }

  static Future<File> ensureTokensExtracted() async {
    final dir = await getModelDirectory();
    final target = File('${dir.path}/$tokensFileName');
    if (!await ZipformerNpuPackage.matches(
      target,
      ZipformerNpuPackage.tokens,
    )) {
      final temporary = File('${target.path}.tmp');
      await temporary.writeAsBytes(await readBundledTokens(), flush: true);
      await temporary.rename(target.path);
    }
    return target;
  }

  static Future<void> downloadRequiredFiles({
    required void Function(double progress, String statusText) onProgress,
  }) async {
    final dir = await getModelDirectory();
    onProgress(0.01, 'استخراج ملف التهيئة المدمج...');
    await ensureContextModelExtracted();
    await ensureTokensExtracted();
    final total = _downloadFiles.fold(0, (sum, entry) => sum + entry.$1.size);
    var completed = 0;
    for (final (spec, label) in _downloadFiles) {
      final target = File('${dir.path}/${spec.name}');
      if (!await compute(_matchesFile, (target.path, spec))) {
        final base = Uri.tryParse(_downloadBaseUrl);
        // A test APK can use ADB reverse with the pinned artifacts, offline.
        final isTestLoopback =
            _testBaseUrl.isNotEmpty &&
            base?.scheme == 'http' &&
            base?.host == '127.0.0.1' &&
            base?.hasPort == true;
        if (base == null ||
            !base.hasAuthority ||
            base.userInfo.isNotEmpty ||
            !base.path.endsWith('/') ||
            (base.scheme != 'https' && !isTestLoopback)) {
          throw const FormatException('Invalid Zipformer download origin');
        }
        onProgress(completed / total * 0.98, 'جارٍ تجهيز $label...');
        await _downloadStreamingFile(
          url: base.resolve(spec.name),
          targetFile: target,
          spec: spec,
          onFileProgress: (received) {
            onProgress(
              (completed + received) / total * 0.98,
              'جارٍ تنزيل $label...',
            );
          },
        );
      }
      completed += spec.size;
    }

    onProgress(0.99, 'التحقق من الرموز الصوتية...');
    await readBundledTokens();
    onProgress(1.0, 'اكتمل تنزيل ملفات Zipformer.');
  }

  static Future<void> _downloadStreamingFile({
    required Uri url,
    required File targetFile,
    required ZipformerFile spec,
    required void Function(int bytes) onFileProgress,
  }) async {
    final client = http.Client();
    final tempFile = File('${targetFile.path}.tmp');
    try {
      final response = await client
          .send(http.Request('GET', url))
          .timeout(_networkTimeout);
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      if (response.contentLength != null &&
          response.contentLength != spec.size) {
        throw const FormatException('Unexpected Zipformer file length');
      }
      final file = await tempFile.open(mode: FileMode.write);
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(_networkTimeout)) {
          received += chunk.length;
          if (received > spec.size) {
            throw const FormatException(
              'Zipformer download exceeds expected size',
            );
          }
          await file.writeFrom(chunk);
          onFileProgress(received);
        }
        await file.flush();
      } finally {
        await file.close();
      }
      if (!await compute(_matchesFile, (tempFile.path, spec))) {
        throw const FormatException('Zipformer SHA-256 mismatch');
      }
      await tempFile.rename(targetFile.path);
    } finally {
      client.close();
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  static Future<String> getOnnxModelPath() async {
    final dir = await getModelDirectory();
    return '${dir.path}/$onnxFileName';
  }

  static Future<String> getPhonemesJsonPath() async {
    final dir = await getModelDirectory();
    return '${dir.path}/$phonemesFileName';
  }

  static Future<String> getTokensPath() async {
    final file = await ensureTokensExtracted();
    return file.path;
  }
}

Future<bool> _verifyNpuFiles(String path) async {
  for (final spec in const [
    ZipformerNpuPackage.context,
    ZipformerNpuPackage.binary,
    ZipformerNpuPackage.phonemes,
  ]) {
    if (!await ZipformerNpuPackage.matches(File('$path/${spec.name}'), spec)) {
      return false;
    }
  }
  return true;
}

Future<bool> _matchesFile((String, ZipformerFile) file) =>
    ZipformerNpuPackage.matches(File(file.$1), file.$2);
