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

import 'package:shared_preferences/shared_preferences.dart';

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
      ..type =
          'page_font' // New type for QPC V1
      ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/qpc_v1_by_page.woff.zip'
      ..localPath =
          'mushafs/madani_old_v1' // Extracted path
      ..pageCount = 604
      ..isDownloaded = false,

    // 3. Madani Matching Shamarly (Images)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('shamarly_15lines')
      ..identifier = 'shamarly_15lines'
      // Updated Name as requested - Hidden "Images" label
      ..nameArabic = 'مصحف المدينة موافق للشمرلي'
      ..nameEnglish = 'Madani Matching Shamarly'
      ..type = 'image'
      ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/quran_images_shamrly.zip'
      ..imageExtension = 'png'
      ..pageCount = 521
      ..isDownloaded = false,

    // 4. Digital (Hidden/Fallback)
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
      'madani_font_v1': 4,
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
    return list.where((m) => m.type != 'digital').toList();
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

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  MushafMetadataProvider() {
    _init();
  }

  Future<void> _init() async {
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
    final mushaf = _availableMushafs.firstWhere(
      (m) => m.identifier == identifier,
      orElse: () => _availableMushafs.first,
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
        await mushaf_downloader.MushafDownloaderService.downloadAndExtract(
          url: mushaf.baseUrl!,
          destinationPath: targetPath,
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
            destinationPath: targetPath,
            onProgress: (p) {
              _downloadProgress = 0.9 + (p * 0.1);
              notifyListeners();
            },
          );
        }
      }

      // Update metadata
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        mushaf.isDownloaded = true;
        mushaf.localPath = targetPath;

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

      notifyListeners();
    } catch (e) {
      debugPrint('Download failed: $e');
      // Show error via snackbar or other UI mechanism if possible
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
      final prefs = await SharedPreferences.getInstance();

      await isar.writeTxn(() async {
        // 1. Check QCF2 Fonts
        final areFontsDownloaded = prefs.getBool('fonts_downloaded') ?? false;
        final qcf2 = await isar
            .collection<db_models.MushafMetadata>()
            .filter()
            .identifierEqualTo('qcf2_v4_woff2')
            .findFirst();
        if (qcf2 != null && areFontsDownloaded) {
          qcf2.isDownloaded = true;
          qcf2.localPath = '${appDir.path}/fonts';
          await isar.collection<db_models.MushafMetadata>().put(qcf2);
        }

        // 2. Check other directories
        final mushafs = await isar
            .collection<db_models.MushafMetadata>()
            .where()
            .findAll();
        for (var m in mushafs) {
          if (m.identifier == 'qcf2_v4_woff2' || m.type == 'digital') continue;

          final dir = Directory('${appDir.path}/mushafs/${m.identifier}');
          if (await dir.exists()) {
            final files = dir.listSync();
            if (files.isNotEmpty) {
              m.isDownloaded = true;
              m.localPath = dir.path;
              await isar.collection<db_models.MushafMetadata>().put(m);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }
}
