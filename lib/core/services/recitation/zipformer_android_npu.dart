import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'recitation_model_downloader.dart';
import 'zipformer_engine.dart';
import 'zipformer_npu_package.dart';

abstract final class ZipformerAndroidNpu {
  static const _channel = MethodChannel('mathani/zipformer_npu');

  static Future<String?> unavailableReason() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'التسميع عبر NPU متاح على أجهزة Android المعتمدة.';
    }
    try {
      final capability = await _channel.invokeMapMethod<String, Object?>(
        'capability',
      );
      if (capability?['supported'] == true) return null;
      return switch (capability?['reason']) {
        'unsupported_soc' =>
          'لم يُعتمد تسميع Zipformer عبر NPU لهذه الشريحة بعد.',
        'unsupported_abi' =>
          'مسار Zipformer عبر NPU يتطلب تطبيق Android بنظام ARM64.',
        _ => 'لم تُحمّل مكتبات تشغيل Zipformer عبر NPU في هذه النسخة.',
      };
    } on PlatformException {
      return 'تعذر التحقق من تهيئة Zipformer عبر NPU.';
    } on MissingPluginException {
      return 'مزوّد تشغيل Zipformer عبر NPU غير موجود في هذه النسخة.';
    }
  }

  static Future<ZipformerNpuStream> openStream() async {
    final reason = await unavailableReason();
    if (reason != null) throw ZipformerNpuUnavailable(reason);
    if (!await RecitationModelDownloader.isModelReady()) {
      throw const ZipformerNpuUnavailable(
        'ملفات Zipformer عبر NPU ناقصة أو تالفة. أعد تجهيزها من مركز التنزيل.',
      );
    }
    final directory = await RecitationModelDownloader.getModelDirectory(
      create: false,
    );
    final tokens = await _readTokens();
    try {
      final session = await _channel.invokeMethod<int>('open', {
        'modelPath': '${directory.path}/${ZipformerNpuPackage.context.name}',
        'tokens': tokens,
      });
      if (session == null || session <= 0) {
        throw const ZipformerNpuUnavailable('لم يُنشئ مزوّد NPU جلسة صالحة.');
      }
      return _AndroidNpuStream(session);
    } on PlatformException catch (error) {
      throw ZipformerNpuUnavailable(switch (error.code) {
        'model_unavailable' => 'تعذّر فتح ملفات Zipformer المجهزة لـNPU.',
        'session_busy' => 'توجد جلسة Zipformer نشطة. أوقفها ثم أعد المحاولة.',
        _ => 'فشل الاختبار الأولي لتشغيل Zipformer على NPU.',
      });
    }
  }

  static Future<List<String>> _readTokens() async {
    try {
      final bytes = await RecitationModelDownloader.readBundledTokens();
      final tokens = List<String>.filled(251, '');
      for (final line in const LineSplitter().convert(utf8.decode(bytes))) {
        if (line.isEmpty) continue;
        final separator = line.lastIndexOf(' ');
        if (separator <= 0) throw const FormatException('Invalid token line');
        final index = int.parse(line.substring(separator + 1));
        if (index < 0 || index >= tokens.length || tokens[index].isNotEmpty) {
          throw const FormatException('Invalid token index');
        }
        tokens[index] = line.substring(0, separator);
      }
      if (tokens[250] != '<blank>' || tokens.any((token) => token.isEmpty)) {
        throw const FormatException('Incomplete token table');
      }
      return tokens;
    } on FormatException {
      throw const ZipformerNpuUnavailable('جدول رموز Zipformer المضمّن تالف.');
    }
  }
}

class _AndroidNpuStream implements ZipformerNpuStream {
  _AndroidNpuStream(this._session);

  final int _session;
  bool _closed = false;

  @override
  Future<String> acceptPcm(Float32List samples) =>
      _decode('acceptPcm', samples);

  @override
  Future<String> finish() => _decode('finish');

  Future<String> _decode(String method, [Float32List? samples]) async {
    if (_closed) throw StateError('Zipformer session has closed');
    final result = await ZipformerAndroidNpu._channel.invokeMethod<String>(
      method,
      {'session': _session, 'samples': ?samples},
    );
    if (result == null) throw StateError('Zipformer did not return phonemes');
    return result;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await ZipformerAndroidNpu._channel.invokeMethod<void>('close', {
      'session': _session,
    });
  }
}
