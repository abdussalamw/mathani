import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/recitation/recitation_model_downloader.dart';
import '../../core/services/recitation/zipformer_npu_package.dart';

enum DiagnosticStatus {
  passed('اجتاز'),
  blocked('يحتاج إجراء'),
  unverified('لم يُختبر'),
  info('معلومة');

  const DiagnosticStatus(this.label);
  final String label;
}

enum RecitationDiagnosticStage {
  engine('اختيار المحرك'),
  npu('تهيئة NPU'),
  download('تنزيل ملفات Zipformer'),
  reference('قراءة مرجع الفونيمات'),
  permission('إذن الميكروفون'),
  recording('فتح الميكروفون'),
  streaming('بث الصوت'),
  matching('مطابقة التلاوة'),
  finalization('إنهاء التحليل'),
  cleanup('إغلاق الجلسة');

  const RecitationDiagnosticStage(this.label);
  final String label;
}

typedef RecitationDiagnosticIssue = ({
  RecitationDiagnosticStage stage,
  String message,
  DateTime occurredAt,
});

class DiagnosticCheckResult {
  const DiagnosticCheckResult({
    required this.name,
    required this.status,
    required this.detail,
    this.action,
  });

  final String name;
  final DiagnosticStatus status;
  final String detail;
  final String? action;
}

class DiagnosticReport {
  const DiagnosticReport({required this.checks, required this.timestamp});

  final List<DiagnosticCheckResult> checks;
  final DateTime timestamp;

  DiagnosticCheckResult? get firstBlocker {
    for (final check in checks) {
      if (check.status == DiagnosticStatus.blocked) return check;
    }
    return null;
  }

  String get summary => firstBlocker?.name ?? 'الفحص الأولي مكتمل';
  String get guidance =>
      firstBlocker?.action ??
      'ابدأ جلسة تسميع للتحقق من سرعة التنبيه وثباته أثناء التلاوة.';

  String toText() {
    final text = StringBuffer()
      ..writeln('تقرير تشخيص التسميع في مثاني')
      ..writeln(timestamp.toIso8601String())
      ..writeln(summary)
      ..writeln(guidance);
    for (final check in checks) {
      text
        ..writeln()
        ..writeln('[${check.status.label}] ${check.name}')
        ..writeln(check.detail);
      if (check.action != null) text.writeln(check.action);
    }
    return text.toString().trimRight();
  }
}

class RecitationDiagnosticService {
  RecitationDiagnosticService({
    Future<Directory> Function()? modelDirectory,
    Future<PermissionStatus> Function()? microphoneStatus,
    AssetBundle? assets,
  }) : _modelDirectory =
           modelDirectory ??
           (() => RecitationModelDownloader.getModelDirectory(create: false)),
       _microphoneStatus =
           microphoneStatus ?? (() => Permission.microphone.status),
       _assets = assets ?? rootBundle;

  static const _platform = MethodChannel('mathani/recitation_diagnostics');
  final Future<Directory> Function() _modelDirectory;
  final Future<PermissionStatus> Function() _microphoneStatus;
  final AssetBundle _assets;

  Future<DiagnosticReport> runAll({
    required bool npuBackendConfigured,
    required bool whisperSelected,
    required bool downloadingModel,
    required bool sessionActive,
    String? npuUnavailableReason,
    DateTime? lastVerifiedNpuAt,
    RecitationDiagnosticIssue? lastIssue,
    void Function(String checkName)? onCheckStarted,
  }) async {
    onCheckStarted?.call('معلومات الجهاز');
    final device = await _deviceInfo();
    onCheckStarted?.call('ملفات Zipformer');
    final files = await _checkModelFiles(downloadingModel);
    onCheckStarted?.call('إذن الميكروفون');
    final microphone = await _checkMicrophone();
    return DiagnosticReport(
      timestamp: DateTime.now(),
      checks: List.unmodifiable([
        DiagnosticCheckResult(
          name: 'المحرك المختار',
          status: whisperSelected
              ? DiagnosticStatus.blocked
              : DiagnosticStatus.passed,
          detail: whisperSelected
              ? 'Whisper محدد في التفضيلات وقيد التطوير.'
              : 'Zipformer V3 هو المحرك المحدد.',
          action: whisperSelected
              ? 'اختر Zipformer V3 من إعدادات التسميع.'
              : null,
        ),
        DiagnosticCheckResult(
          name: 'توافق الجهاز مع مسار NPU',
          status: npuBackendConfigured
              ? DiagnosticStatus.passed
              : DiagnosticStatus.blocked,
          detail: npuBackendConfigured
              ? 'الجهاز مؤهل لمسار QNN عبر Hexagon. يُختبر الاستدلال عند البدء.'
              : npuUnavailableReason ??
                    'مسار Zipformer على NPU غير متاح للجهاز حاليًا.',
          action: npuBackendConfigured
              ? null
              : 'راجع بيانات الجهاز وإصدار مثاني أدناه.',
        ),
        ...files,
        _npuExecutionCheck(
          npuBackendConfigured: npuBackendConfigured,
          lastVerifiedAt: lastVerifiedNpuAt,
          lastIssue: lastIssue,
        ),
        microphone,
        device,
        DiagnosticCheckResult(
          name: 'اختبار التسجيل أثناء التلاوة',
          status: DiagnosticStatus.unverified,
          detail: sessionActive
              ? 'توجد جلسة نشطة. الفحص لم يتدخل فيها.'
              : 'يعرض الفحص حالة الإذن. قياس التنبيه يتطلب جلسة تلاوة.',
          action: 'يلزم اختبار فعلي لقياس سرعة التنبيه وثباته أثناء التلاوة.',
        ),
        if (lastIssue != null)
          DiagnosticCheckResult(
            name: 'آخر تعثر منذ فتح التطبيق',
            status: DiagnosticStatus.info,
            detail:
                '${lastIssue.stage.label} [${lastIssue.stage.name}]\n'
                '${lastIssue.message}\n${lastIssue.occurredAt.toIso8601String()}',
          ),
      ]),
    );
  }

  DiagnosticCheckResult _npuExecutionCheck({
    required bool npuBackendConfigured,
    required DateTime? lastVerifiedAt,
    required RecitationDiagnosticIssue? lastIssue,
  }) {
    const name = 'التحقق من استدلال NPU';
    if (npuBackendConfigured &&
        lastIssue != null &&
        lastIssue.stage == RecitationDiagnosticStage.npu &&
        (lastVerifiedAt == null ||
            !lastIssue.occurredAt.isBefore(lastVerifiedAt))) {
      return DiagnosticCheckResult(
        name: name,
        status: DiagnosticStatus.blocked,
        detail: 'تعذّر تحقق NPU في آخر محاولة. ${lastIssue.message}',
        action: 'راجع ملفات النموذج ثم أعد محاولة بدء التسميع.',
      );
    }
    if (npuBackendConfigured && lastVerifiedAt != null) {
      return DiagnosticCheckResult(
        name: name,
        status: DiagnosticStatus.passed,
        detail:
            'نجح اختبار النموذج على Hexagon عند تهيئة آخر جلسة '
            'وكان تشغيل عمليات النموذج على CPU معطّلًا.\n'
            '${lastVerifiedAt.toIso8601String()}',
      );
    }
    return DiagnosticCheckResult(
      name: name,
      status: DiagnosticStatus.unverified,
      detail: 'تُختبر دفعة قبل فتح الميكروفون عند بدء التسميع.',
      action: npuBackendConfigured
          ? 'ابدأ جلسة بعد اكتمال ملفات النموذج.'
          : null,
    );
  }

  Future<DiagnosticCheckResult> _deviceInfo() async {
    Map<String, Object?> info = {};
    try {
      info =
          await _platform.invokeMapMethod<String, Object?>('deviceInfo') ?? {};
    } on PlatformException {
      // Fall back to public OS metadata.
    } on MissingPluginException {
      // The optional Android channel may be unavailable on this build/platform.
    }
    final description = [
      if (info['model'] case final String model)
        'الجهاز ${info['manufacturer'] ?? ''} $model',
      if (info['soc'] case final String soc)
        'الشريحة ${info['socManufacturer'] ?? ''} $soc',
      if (info['sdk'] case final int sdk)
        'Android ${info['release']} (API $sdk)',
      if (info['abis'] case final List abis)
        'واجهات ABI المدعومة ${abis.join(', ')}',
      if (info['appVersion'] case final String appVersion)
        'مثاني $appVersion (${info['appBuild']})',
      if (info.isEmpty) 'النظام ${kIsWeb ? 'Web' : Platform.operatingSystem}',
    ];
    return DiagnosticCheckResult(
      name: 'الجهاز ونسخة التطبيق',
      status: DiagnosticStatus.info,
      detail: description.join('\n'),
      action: info.isEmpty
          ? 'تفاصيل الجهاز والإصدار غير متاحة في هذه البيئة.'
          : null,
    );
  }

  Future<List<DiagnosticCheckResult>> _checkModelFiles(bool downloading) async {
    DiagnosticCheckResult bundledTokens;
    try {
      final data = await _assets.load('assets/data/tokens.txt');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final tokens = ZipformerNpuPackage.tokens;
      final matches =
          bytes.length == tokens.size &&
          crypto.sha256.convert(bytes).toString() == tokens.sha256;
      bundledTokens = DiagnosticCheckResult(
        name: 'جدول الرموز المضمّن',
        status: matches ? DiagnosticStatus.passed : DiagnosticStatus.blocked,
        detail: matches
            ? 'يطابق جدول Zipformer V3 المرجعي المضمّن.'
            : 'الجدول المضمّن مختلف عن مرجع Zipformer V3.',
        action: matches ? null : 'تحقّق من سلامة نسخة مثاني.',
      );
    } catch (_) {
      bundledTokens = const DiagnosticCheckResult(
        name: 'جدول الرموز المضمّن',
        status: DiagnosticStatus.blocked,
        detail: 'تعذّرت قراءة جدول الرموز من أصول التطبيق.',
        action: 'تحقّق من سلامة نسخة مثاني.',
      );
    }
    if (kIsWeb) {
      return [
        const DiagnosticCheckResult(
          name: 'ملفات Zipformer المحلية',
          status: DiagnosticStatus.unverified,
          detail: 'فحص مجلد نموذج Android متاح في تطبيق الهاتف.',
        ),
        bundledTokens,
      ];
    }
    if (downloading) {
      return [
        const DiagnosticCheckResult(
          name: 'ملفات Zipformer',
          status: DiagnosticStatus.unverified,
          detail: 'يجري تنزيل الملفات الآن.',
          action: 'أعد الفحص بعد اكتمال التنزيل.',
        ),
        bundledTokens,
      ];
    }
    try {
      final dir = await _modelDirectory();
      final installed = await compute(_inspectInstalledFiles, dir.path);
      return [...installed, bundledTokens];
    } catch (_) {
      return [
        const DiagnosticCheckResult(
          name: 'مجلد ملفات Zipformer',
          status: DiagnosticStatus.blocked,
          detail: 'تعذّر الوصول إلى مساحة ملفات النموذج.',
          action: 'تحقّق من مساحة التخزين ثم أعد الفحص.',
        ),
        bundledTokens,
      ];
    }
  }

  Future<DiagnosticCheckResult> _checkMicrophone() async {
    try {
      final result = await _microphoneStatus();
      return DiagnosticCheckResult(
        name: 'إذن الميكروفون',
        status: result.isGranted
            ? DiagnosticStatus.passed
            : DiagnosticStatus.blocked,
        detail: switch (result) {
          PermissionStatus.granted => 'الإذن ممنوح.',
          PermissionStatus.permanentlyDenied =>
            'الإذن مرفوض ويحتاج تفعيلًا من إعدادات الجهاز.',
          PermissionStatus.restricted =>
            'إعدادات النظام تقيّد الوصول إلى الميكروفون.',
          _ => 'الإذن غير ممنوح.',
        },
        action: result.isGranted
            ? null
            : 'راجع إذن الميكروفون لمثاني في إعدادات الجهاز.',
      );
    } catch (_) {
      return const DiagnosticCheckResult(
        name: 'إذن الميكروفون',
        status: DiagnosticStatus.unverified,
        detail: 'تعذّرت قراءة حالة الإذن على هذه المنصة.',
      );
    }
  }
}

const _fingerprints = {
  'ملف سياق QNN': ZipformerNpuPackage.context,
  'النموذج المجمّع لـHexagon': ZipformerNpuPackage.binary,
  'مرجع الفونيمات': ZipformerNpuPackage.phonemes,
};

Future<List<DiagnosticCheckResult>> _inspectInstalledFiles(
  String directory,
) async {
  return [
    for (final MapEntry(key: label, value: fingerprint)
        in _fingerprints.entries)
      await _inspectInstalledFile(directory, label, fingerprint),
  ];
}

Future<DiagnosticCheckResult> _inspectInstalledFile(
  String directory,
  String label,
  ZipformerFile fingerprint,
) async {
  final file = File('$directory/${fingerprint.name}');
  const retry = 'راجع ملفات Zipformer في مركز التحميل ثم أعد الفحص.';
  try {
    final stat = await file.stat();
    final expected = 'المتوقع ${fingerprint.size} بايت';
    if (stat.type == FileSystemEntityType.notFound) {
      final partial = await File('${file.path}.tmp').exists();
      return DiagnosticCheckResult(
        name: label,
        status: DiagnosticStatus.blocked,
        detail:
            '${fingerprint.name}\n${partial ? 'بقي ملف مؤقت من تنزيل غير مكتمل.' : 'الملف مفقود.'}\n$expected',
        action: retry,
      );
    }
    if (stat.type != FileSystemEntityType.file ||
        stat.size != fingerprint.size) {
      return DiagnosticCheckResult(
        name: label,
        status: DiagnosticStatus.blocked,
        detail: '${fingerprint.name}\nحجم الملف ${stat.size} بايت. $expected.',
        action: retry,
      );
    }

    final matches = await ZipformerNpuPackage.matches(file, fingerprint);
    return DiagnosticCheckResult(
      name: label,
      status: matches ? DiagnosticStatus.passed : DiagnosticStatus.blocked,
      detail:
          '${fingerprint.name}\n${stat.size} بايت\n'
          '${matches ? 'تطابق بصمة SHA-256 الملف المعتمد.' : 'تعذّر التحقق من تطابق بصمة SHA-256 مع الملف المعتمد.'}',
      action: matches ? null : retry,
    );
  } on FileSystemException {
    return DiagnosticCheckResult(
      name: label,
      status: DiagnosticStatus.unverified,
      detail: 'تعذّرت قراءة ${fingerprint.name}.',
      action: retry,
    );
  }
}
