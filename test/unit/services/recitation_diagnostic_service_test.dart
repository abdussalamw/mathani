import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/zipformer_npu_package.dart';
import 'package:mathani/data/services/recitation_diagnostic_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const deviceChannel = MethodChannel('mathani/recitation_diagnostics');
  late Directory storage;

  setUp(() async {
    storage = await Directory.systemTemp.createTemp('mathani-diagnostic-');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(deviceChannel, (
      call,
    ) async {
      expect(call.method, 'deviceInfo');
      return {
        'manufacturer': 'Samsung',
        'model': 'SM-S928B',
        'soc': 'SM8650',
        'socManufacturer': 'Qualcomm',
        'release': '15',
        'sdk': 35,
        'abis': ['arm64-v8a'],
        'appVersion': '1.0.2',
        'appBuild': 16,
        'serial': 'private-serial-not-in-report',
      };
    });
  });

  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      deviceChannel,
      null,
    );
    await storage.delete(recursive: true);
  });

  DiagnosticCheckResult check(DiagnosticReport report, String name) =>
      report.checks.singleWhere((item) => item.name == name);

  test(
    'separates unavailable runtime from device, missing files and permission',
    () async {
      final service = RecitationDiagnosticService(
        modelDirectory: () async => storage,
        microphoneStatus: () async => PermissionStatus.permanentlyDenied,
      );
      final result = await service.runAll(
        npuBackendConfigured: false,
        whisperSelected: false,
        downloadingModel: false,
        sessionActive: false,
        npuUnavailableReason: 'مكتبات QNN غير متاحة في هذه النسخة.',
        lastIssue: (
          stage: RecitationDiagnosticStage.npu,
          message: 'تعذّر تهيئة المحرك.',
          occurredAt: DateTime.utc(2026, 11, 19),
        ),
      );

      expect(result.firstBlocker?.name, 'توافق الجهاز مع مسار NPU');
      expect(result.firstBlocker?.detail, contains('مكتبات QNN'));
      expect(check(result, 'ملف سياق QNN').detail, contains('مفقود'));
      expect(
        check(result, 'إذن الميكروفون').detail,
        contains('إعدادات الجهاز'),
      );
      expect(
        check(result, 'التحقق من استدلال NPU').status,
        DiagnosticStatus.unverified,
      );
      expect(
        check(result, 'جدول الرموز المضمّن').status,
        DiagnosticStatus.passed,
      );
      final text = result.toText();
      expect(text, contains('SM-S928B'));
      expect(text, contains('SM8650'));
      expect(text, contains('Android 15 (API 35)'));
      expect(text, contains('1.0.2 (16)'));
      expect(text, contains('[npu]'));
      expect(text, isNot(contains('private-serial-not-in-report')));
      expect(text, isNot(contains(storage.path)));
    },
  );

  test(
    'detects partial download and same-size corruption in the QNN context',
    () async {
      final dir = Directory('${storage.path}/recitation_models');
      await dir.create();
      final entry = File('${dir.path}/${ZipformerNpuPackage.context.name}');
      await File('${entry.path}.tmp').writeAsBytes([1, 2, 3]);
      final service = RecitationDiagnosticService(
        modelDirectory: () async => dir,
        microphoneStatus: () async => PermissionStatus.granted,
      );
      Future<DiagnosticReport> run() => service.runAll(
        npuBackendConfigured: true,
        whisperSelected: false,
        downloadingModel: false,
        sessionActive: false,
      );

      final clean = await run();
      expect(
        check(clean, 'توافق الجهاز مع مسار NPU').status,
        DiagnosticStatus.passed,
      );
      expect(check(clean, 'ملف سياق QNN').detail, contains('تنزيل غير مكتمل'));
      expect(
        check(clean, 'جدول الرموز المضمّن').status,
        DiagnosticStatus.passed,
      );
      expect(
        check(clean, 'التحقق من استدلال NPU').status,
        DiagnosticStatus.unverified,
      );

      await entry.writeAsBytes(
        List.filled(ZipformerNpuPackage.context.size, 0),
      );
      final damaged = await run();
      final context = check(damaged, 'ملف سياق QNN');
      expect(await entry.length(), ZipformerNpuPackage.context.size);
      expect(context.status, DiagnosticStatus.blocked);
      expect(context.detail, contains('تعذّر التحقق من تطابق بصمة SHA-256'));
    },
  );

  test(
    'does not inspect files during installation and reports legacy selection',
    () async {
      final service = RecitationDiagnosticService(
        modelDirectory: () async => fail('No file inspection during download.'),
        microphoneStatus: () async =>
            throw PlatformException(code: 'unavailable'),
      );
      final result = await service.runAll(
        npuBackendConfigured: false,
        whisperSelected: true,
        downloadingModel: true,
        sessionActive: true,
      );

      expect(result.firstBlocker?.name, 'المحرك المختار');
      expect(
        check(result, 'ملفات Zipformer').status,
        DiagnosticStatus.unverified,
      );
      expect(
        check(result, 'إذن الميكروفون').status,
        DiagnosticStatus.unverified,
      );
      expect(
        check(result, 'اختبار التسجيل أثناء التلاوة').detail,
        contains('جلسة نشطة'),
      );
    },
  );

  test('shows storage errors without exposing paths or leaking platform exceptions', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      deviceChannel,
      null,
    );
    final service = RecitationDiagnosticService(
      modelDirectory: () async =>
          throw const FileSystemException('unreadable', '/private/storage'),
      microphoneStatus: () async => PermissionStatus.granted,
    );
    final result = await service.runAll(
      npuBackendConfigured: true,
      whisperSelected: false,
      downloadingModel: false,
      sessionActive: false,
    );

    expect(result.firstBlocker?.name, 'مجلد ملفات Zipformer');
    expect(
      check(result, 'الجهاز ونسخة التطبيق').detail,
      contains(Platform.operatingSystem),
    );
    expect(result.toText(), isNot(contains('/private/storage')));
  });

  test('reports a real verification separately from recording', () async {
    final service = RecitationDiagnosticService(
      modelDirectory: () async => storage,
      microphoneStatus: () async => PermissionStatus.granted,
    );
    final verifiedAt = DateTime.utc(2026, 11, 19, 14);
    Future<DiagnosticReport> run({RecitationDiagnosticIssue? issue}) =>
        service.runAll(
          npuBackendConfigured: true,
          whisperSelected: false,
          downloadingModel: false,
          sessionActive: false,
          lastVerifiedNpuAt: verifiedAt,
          lastIssue: issue,
        );

    final completed = await run();
    final verification = check(completed, 'التحقق من استدلال NPU');
    expect(verification.status, DiagnosticStatus.passed);
    expect(verification.detail, contains(verifiedAt.toIso8601String()));
    expect(
      check(completed, 'اختبار التسجيل أثناء التلاوة').status,
      DiagnosticStatus.unverified,
    );
    final failed = await run(
      issue: (
        stage: RecitationDiagnosticStage.npu,
        message: 'تعذّر التحقق من الاستدلال.',
        occurredAt: verifiedAt.add(const Duration(seconds: 1)),
      ),
    );
    expect(
      check(failed, 'التحقق من استدلال NPU').status,
      DiagnosticStatus.blocked,
    );
  });

  const labDirectory = '.dart_tool/zipformer_npu';
  const referenceDirectory = 'model_zipformer';
  final localFiles = {
    ZipformerNpuPackage.context: labDirectory,
    ZipformerNpuPackage.binary: labDirectory,
    ZipformerNpuPackage.phonemes: referenceDirectory,
  };
  final hasLocalModel = localFiles.entries.every(
    (entry) => File('${entry.value}/${entry.key.name}').existsSync(),
  );
  test(
    'accepts the verified QNN package without a legacy ONNX model',
    () async {
      for (final entry in localFiles.entries) {
        final name = entry.key.name;
        await File('${entry.value}/$name').copy('${storage.path}/$name');
      }
      final result =
          await RecitationDiagnosticService(
            modelDirectory: () async => storage,
            microphoneStatus: () async => PermissionStatus.granted,
          ).runAll(
            npuBackendConfigured: true,
            whisperSelected: false,
            downloadingModel: false,
            sessionActive: false,
          );

      for (final name in [
        'ملف سياق QNN',
        'النموذج المجمّع لـHexagon',
        'مرجع الفونيمات',
        'جدول الرموز المضمّن',
      ]) {
        expect(
          check(result, name).status,
          DiagnosticStatus.passed,
          reason: name,
        );
      }
      expect(result.firstBlocker, isNull);
      expect(
        check(result, 'التحقق من استدلال NPU').status,
        DiagnosticStatus.unverified,
      );
    },
    skip: hasLocalModel ? null : 'Local verified NPU package is not staged.',
  );
}
