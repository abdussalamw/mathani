import '../../data/services/mushaf_package.dart';
import '../../data/services/qpc_v1_data_service.dart';
import '../../data/services/qpc_v1_layout_service.dart';
import '../../data/services/qpc_v1_alignment_service.dart';
import '../../data/services/shamarly_data_loader.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import 'package:path_provider/path_provider.dart';

import '../../core/database/collections.dart' as db_models; // Alias
import '../../core/database/isar_service.dart';
import '../../data/services/mushaf_downloader_service.dart'
    as mushaf_downloader;
import '../../core/di/service_locator.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/user_settings.dart';

import '../../data/services/qcf4_font_downloader.dart';

class MushafMetadataProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository = sl<SettingsRepository>();

  // القائمة الثابتة كـ Fallback في حال فشل الداتابيز
  final List<db_models.MushafMetadata> _fallbackMushafs = [
    // 1. Madani New Script (Default & Vector/Font)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('qcf2_v4_woff2')
      ..identifier = 'qcf2_v4_woff2'
      ..nameArabic = 'مصحف المدينة - الرسم الجديد'
      ..nameEnglish = 'Madani Mushaf - New Script'
      ..type = 'font_v2'
      ..baseUrl =
          null // Bundled assets
      ..localPath = 'assets/fonts/qcf2'
      ..isDownloaded = false,

    // 2. Madani Old Script (Fonts - QPC V1)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_old_v1')
      ..identifier = 'madani_old_v1'
      ..nameArabic = 'مصحف المدينة ـ الرسم القديم'
      ..nameEnglish = 'Madani Mushaf - Old Script'
      ..type = 'page_font' // Type for QPC V1
      ..baseUrl =
          'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/qpc_v1_by_page.woff.zip'
      ..localPath = 'mushafs/madani_old_v1' // Extracted path
      ..pageCount = 604
      ..totalPages = 604
      ..isDownloaded = false,

    // 3. Madani Matching Shamarly (Images)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('shamarly_15lines')
      ..identifier = 'shamarly_15lines'
      // Updated Name as requested - Hidden "Images" label
      ..nameArabic = 'مصحف المدينة موافق للشمرلي'
      ..nameEnglish = 'Madani Matching Shamarly'
      ..type = 'image'
      ..baseUrl =
          'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/quran_images_shamrly.zip'
      ..imageExtension = 'png'
      ..pageCount = 521
      ..isDownloaded = false,

    // 4. Medina 1441 trial with a single bundled OpenType font
    db_models.MushafMetadata()
      ..id = db_models.fastHash('digital_khatt_1441')
      ..identifier = 'digital_khatt_1441'
      ..nameArabic = 'مصحف المدينة 1441 (تجريبي)'
      ..nameEnglish = 'Medina Mushaf 1441 (DigitalKhatt)'
      ..type = 'single_font'
      ..pageCount = 604
      ..totalPages = 604
      ..isDownloaded = true,

    // 5. Medina 1995 trial with a single bundled OpenType font
    db_models.MushafMetadata()
      ..id = db_models.fastHash('digital_khatt_old_madina')
      ..identifier = 'digital_khatt_old_madina'
      ..nameArabic = 'مصحف المدينة 1995 (تجريبي)'
      ..nameEnglish = 'Old Medina Mushaf 1995 (DigitalKhatt)'
      ..type = 'single_font'
      ..baseUrl = null
      ..localPath = 'assets/fonts/digital_khatt'
      ..pageCount = 604
      ..totalPages = 604
      ..isDownloaded = true,

    // 6. Digital (Hidden/Fallback)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_font_v1')
      ..identifier = 'madani_font_v1'
      ..nameArabic = 'المصحف الإلكتروني (نص رقمي)'
      ..nameEnglish = 'Digital Mushaf (System Text)'
      ..type = 'digital'
      ..isDownloaded = true,
  ];

  // Helper to maintain sort order
  void _sortMushafs(List<db_models.MushafMetadata> list) {
    const order = {
      'qcf2_v4_woff2': 1,
      'madani_old_v1': 2,
      'shamarly_15lines': 3,
      'digital_khatt_1441': 4,
      'digital_khatt_old_madina': 5,
      'madani_font_v1': 6,
    };
    list.sort((a, b) {
      final orderA = order[a.identifier] ?? 99;
      final orderB = order[b.identifier] ?? 99;
      return orderA.compareTo(orderB);
    });
  }

  List<db_models.MushafMetadata> _availableMushafs = [];
  // Filter out 'digital' type from the UI list as requested
  List<db_models.MushafMetadata> get availableMushafs {
    final list = _availableMushafs.isNotEmpty
        ? _availableMushafs
        : _fallbackMushafs;
    return list
        .where((m) => m.type != 'digital' && (!kIsWeb || m.type != 'single_font'))
        .toList();
  }

  String? _currentMushafId;
  // Default to 'qcf2_v4_woff2' (Madani New Script)
  String get currentMushafId => _currentMushafId ?? 'qcf2_v4_woff2';

  String get currentMushafType {
    if (_currentMushafId == null) return 'digital';

    // Find in available list
    try {
      final mushaf = _availableMushafs.firstWhere(
        (m) => m.identifier == _currentMushafId,
      );
      return mushaf.type ?? 'digital';
    } catch (_) {
      return 'digital';
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _currentDownloadingId;
  String? get currentDownloadingId => _currentDownloadingId;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  Object? _initializationError;
  Object? get initializationError => _initializationError;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late final Future<void> initialized;

  MushafMetadataProvider() {
    initialized = _init();
  }

  Future<void> _init() async {
    _initializationError = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Skip Isar on Web
      if (kIsWeb) {
        _availableMushafs = _fallbackMushafs;
        _currentMushafId = 'madani_font_v1';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final isar = IsarService.instance.isar;

      // جلب البيانات من الداتا بيز
      var mushafs = await isar
          .collection<db_models.MushafMetadata>()
          .where()
          .findAll();

      // تزامن البيانات: تأكد من أن كل المصاحف المعرفة في الكود موجودة ومحدثة في قاعدة البيانات
      await isar.writeTxn(() async {
        for (var fallback in _fallbackMushafs) {
          // إذا لم يكن موجوداً، أو إذا نحتاج لتحديث الروابط
          // نلاحظ هنا المقارنة بالـ identifier لأن fallback المرجع هو كائن جديد
          final isNew = !mushafs.any(
            (m) => m.identifier == fallback.identifier,
          );

          if (isNew) {
            await isar.collection<db_models.MushafMetadata>().put(fallback);
          } else {
            // تحديث البيانات الأساسية (URL, Name, e.g.) للموجود
            final existingItem = mushafs.firstWhere(
              (m) => m.identifier == fallback.identifier,
            );

            // فقط نحدث الحقول التي قد تتغير من الكود
            existingItem.baseUrl = fallback.baseUrl;
            existingItem.imageExtension = fallback.imageExtension;
            existingItem.nameArabic = fallback.nameArabic;
            existingItem.type = fallback.type;
            if (fallback.type == 'single_font') {
              existingItem.isDownloaded = true;
              existingItem.localPath = fallback.localPath;
            } else if (fallback.type == 'page_font') {
              existingItem.localPath = fallback.localPath;
            }
            existingItem.pageCount = fallback.pageCount;

            await isar.collection<db_models.MushafMetadata>().put(existingItem);
          }
        }
      });

      // إعادة الجلب بعد التحديث
      mushafs = await isar
          .collection<db_models.MushafMetadata>()
          .where()
          .findAll();

      // تحديث القائمة في الذاكرة
      if (mushafs.isNotEmpty) {
        _sortMushafs(mushafs);
        _availableMushafs = mushafs;
      } else {
        _sortMushafs(_fallbackMushafs);
        _availableMushafs = _fallbackMushafs;
      }

      final result = await _settingsRepository.getSettings();
      result.fold((failure) => _currentMushafId = 'qcf2_v4_woff2', (settings) {
        _currentMushafId = settings.selectedMushafId;
      });
      await syncWithDownloadedFonts();
    } catch (e) {
      _initializationError = e;
      debugPrint('MushafProvider Error: $e');
      _availableMushafs = _fallbackMushafs;
      _currentMushafId = 'qcf2_v4_woff2';
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _init();
  }

  Future<void> setMushaf(String identifier) async {
    final result = await _settingsRepository.getSettings();

    // We get current settings, modify them, and save
    final currentSettings = result.fold(
      (l) => UserSettings.defaults(),
      (r) => r,
    ); // Fix getOrElse by using fold

    final newSettings = currentSettings.copyWith(selectedMushafId: identifier);

    await _settingsRepository.saveSettings(newSettings);

    _currentMushafId = identifier;
    notifyListeners();
  }

  Future<void> downloadMushaf(String identifier) async {
    if (_isDownloading) throw StateError('يوجد تنزيل قيد التنفيذ');
    final mushaf = _availableMushafs.firstWhere(
      (m) => m.identifier == identifier,
    );

    if (identifier != 'qcf2_v4_woff2' && mushaf.baseUrl == null) return;

    _isDownloading = true;
    _currentDownloadingId = identifier;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      String targetPath = '${appDir.path}/mushafs/$identifier';

      if (identifier == 'qcf2_v4_woff2') {
        await QCF4FontDownloader.downloadAllFonts(
          onProgress: (progress) {
            _downloadProgress = progress;
            notifyListeners();
          },
          onStatusChanged: (_) {},
        );
        targetPath = '${appDir.path}/fonts';
      } else {
        final target = Directory(targetPath);
        await target.parent.create(recursive: true);
        final stage = await target.parent.createTemp('.$identifier-install-');
        try {
          await mushaf_downloader.MushafDownloaderService.downloadAndExtract(
            url: mushaf.baseUrl!,
            destinationPath: stage.path,
            onProgress: (progress) {
              _downloadProgress = identifier == 'madani_old_v1'
                  ? progress * 0.9
                  : progress;
              notifyListeners();
            },
          );

          if (identifier == 'madani_old_v1') {
            await mushaf_downloader.MushafDownloaderService.downloadAndExtract(
              url: 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/qpc_v1_json_data.zip',
              destinationPath: stage.path,
              onProgress: (p) {
                _downloadProgress = 0.9 + (p * 0.1);
                notifyListeners();
              },
            );
          }
          if (!await validMushafPackage(identifier, stage)) {
            throw const FormatException('ملفات المصحف ناقصة أو تالفة');
          }
          commitMushafDirectory(stage, target);
          if (identifier == 'madani_old_v1') {
            QPCV1DataService().invalidate();
            QPCV1LayoutService().invalidate();
            QPCV1AlignmentService().invalidate();
          } else if (identifier == 'shamarly_15lines') {
            ShamarlyDataLoader.clearCache();
          }
        } finally {
          if (await stage.exists()) await stage.delete(recursive: true);
        }
      }

      // Update metadata
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        // Update in DB
        final existing = await isar
            .collection<db_models.MushafMetadata>()
            .filter()
            .identifierEqualTo(identifier)
            .findFirst();

        if (existing != null) {
          existing.isDownloaded = true;
          existing.localPath = targetPath;
          await isar.collection<db_models.MushafMetadata>().put(existing);
        }
      });

      mushaf.isDownloaded = true;
      mushaf.localPath = targetPath;
      notifyListeners();
    } catch (e) {
      debugPrint('Download failed: $e');
      rethrow;
    } finally {
      _isDownloading = false;
      _currentDownloadingId = null;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> syncWithDownloadedFonts() async {
    try {
      final isar = IsarService.instance.isar;
      final appDir = await getApplicationDocumentsDirectory();

      // 1. Verify QCF2 Fonts
      final qcfValid = await QCF4FontDownloader.areAllFontsAvailable();

      // 2. Verify QPC V1 Fonts & Glyphs
      final qpcDir = Directory('${appDir.path}/mushafs/madani_old_v1');
      final shamarlyDir = Directory('${appDir.path}/mushafs/shamarly_15lines');
      recoverMushafDirectory(qpcDir);
      recoverMushafDirectory(shamarlyDir);
      final qpcValid = await validMushafPackage('madani_old_v1', qpcDir);
      final shamarlyValid = await validMushafPackage(
        'shamarly_15lines',
        shamarlyDir,
      );

      await isar.writeTxn(() async {
        final mushafs = await isar
            .collection<db_models.MushafMetadata>()
            .where()
            .findAll();

        for (var m in mushafs) {
          if (m.type == 'digital' || m.type == 'single_font') {
            m.isDownloaded = true;
          } else if (m.identifier == 'qcf2_v4_woff2') {
            m.isDownloaded = qcfValid;
            if (qcfValid) m.localPath = '${appDir.path}/fonts';
          } else if (m.identifier == 'madani_old_v1') {
            m.isDownloaded = qpcValid;
            if (qpcValid) m.localPath = qpcDir.path;
          } else if (m.identifier == 'shamarly_15lines') {
            m.isDownloaded = shamarlyValid;
            if (shamarlyValid) m.localPath = shamarlyDir.path;
          }
          await isar.collection<db_models.MushafMetadata>().put(m);
        }
      });

      // Synchronize in-memory list
      final updatedMushafs = await isar
          .collection<db_models.MushafMetadata>()
          .where()
          .findAll();
      if (updatedMushafs.isNotEmpty) {
        _sortMushafs(updatedMushafs);
        _availableMushafs = updatedMushafs;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Sync error: $e');
      rethrow;
    }
  }
}
