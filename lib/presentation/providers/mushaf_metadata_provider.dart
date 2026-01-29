import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../../core/network/api_client.dart';
import '../../core/database/collections.dart' as db_models; // Alias
import '../../core/database/isar_service.dart';
import '../../core/di/service_locator.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../domain/entities/user_settings.dart';

class MushafMetadataProvider extends ChangeNotifier {
  final GetSettingsUseCase _getSettingsUseCase = sl<GetSettingsUseCase>();
  final SaveSettingsUseCase _saveSettingsUseCase = sl<SaveSettingsUseCase>();
  
  // القائمة الثابتة كـ Fallback في حال فشل الداتابيز
  final List<db_models.MushafMetadata> _fallbackMushafs = [
    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_font_v1')
      ..identifier = 'madani_font_v1'
      ..nameArabic = 'مصحف المدينة (نص رقمي)'
      ..nameEnglish = 'Madani (Font - V1)'
      ..type = 'font'
      ..isDownloaded = true, 
      
    db_models.MushafMetadata()
      ..id = db_models.fastHash('qcf2_v4_woff2')
      ..identifier = 'qcf2_v4_woff2'
      ..nameArabic = 'مصحف المدينة (QCF2 - V4)'
      ..nameEnglish = 'Madani (QCF2 V4)'
      ..type = 'font_v2'
      ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/quran_fonts_qfc4.zip'
      ..isDownloaded = false,

    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_images_15lines')
      ..identifier = 'madani_images_15lines'
      ..nameArabic = 'مصحف المدينة (صور)'
      ..nameEnglish = 'Madani (Images)'
      ..type = 'image'
      ..baseUrl = 'https://android.quran.com/data/width_1024/page'
      ..isDownloaded = false,
  ];

  List<db_models.MushafMetadata> _availableMushafs = [];
  List<db_models.MushafMetadata> get availableMushafs => _availableMushafs.isNotEmpty ? _availableMushafs : _fallbackMushafs;

  String? _currentMushafId;
  String get currentMushafId => _currentMushafId ?? 'madani_font_v1';

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;
  
  String? _currentDownloadingId;
  String? get currentDownloadingId => _currentDownloadingId;
  
  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  MushafMetadataProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isar = IsarService.instance.isar; // Fix getter
      
      // جلب البيانات من الداتا بيز
      var mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll(); // Use alias

      // إذا كانت فارغة تماماً، نحاول زرعها
      if (mushafs.isEmpty) {
        await _seedDefaultMushafs(isar);
        mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll();
      }

      // تحديث القائمة في الذاكرة
      if (mushafs.isNotEmpty) {
        _availableMushafs = mushafs;
      } else {
        // إذا فشل كل شيء، نستخدم القائمة الثابتة
        _availableMushafs = _fallbackMushafs;
      }

      final result = await _getSettingsUseCase();
      result.fold(
        (failure) => _currentMushafId = 'madani_font_v1',
        (settings) => _currentMushafId = settings.selectedMushafId,
      );
    } catch (e) {
      debugPrint('MushafProvider Error: $e');
      _availableMushafs = _fallbackMushafs; // الأمان أولاً
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _init();
  }

  Future<void> _seedDefaultMushafs(Isar isar) async {
    try {
      await isar.writeTxn(() async {
        for (var mushaf in _fallbackMushafs) {
           // نستخدم put لضمان الكتابة
           await isar.collection<db_models.MushafMetadata>().put(mushaf);
        }
      });
    } catch (e) {
      debugPrint('Seeding failed: $e');
    }
  }

  Future<void> setMushaf(String identifier) async {
    final result = await _getSettingsUseCase();
    
    // We get current settings, modify them, and save
    final currentSettings = result.fold(
      (l) => UserSettings.defaults(), 
      (r) => r
    ); // Fix getOrElse by using fold
    
    final newSettings = currentSettings.copyWith(selectedMushafId: identifier);
    
    await _saveSettingsUseCase(newSettings);
    
    _currentMushafId = identifier;
    notifyListeners();
  }

  Future<void> downloadMushaf(String identifier) async {
    final mushaf = availableMushafs.firstWhere((m) => m.identifier == identifier);
    if (mushaf.baseUrl == null || _isDownloading) return;

    _isDownloading = true;
    _currentDownloadingId = identifier;
    _downloadProgress = 0;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${dir.path}/mushaf_assets/$identifier');
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
      
      final zipPath = '${targetDir.path}/assets.zip';
      
      // Using direct Dio for download as ApiClient usually wraps requests, 
      // but we can instantiate a fresh Dio or use the one from client if exposed.
      // Ideally ApiClient should have a download method.
      // For now, let's keep it simple but ensure error handling.
      await Dio().download(mushaf.baseUrl!, zipPath, onReceiveProgress: (received, total) {
        if (total != -1) {
          _downloadProgress = received / total;
          notifyListeners();
        }
      });

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${targetDir.path}/${file.name}')..createSync(recursive: true)..writeAsBytesSync(data);
        }
      }
      File(zipPath).deleteSync();

      final isar = IsarService.instance.isar; // Fix getter
      await isar.writeTxn(() async {
        final mToUpdate = await isar.collection<db_models.MushafMetadata>().filter().identifierEqualTo(identifier).findFirst(); // Use alias
        if (mToUpdate != null) {
          mToUpdate.isDownloaded = true;
          mToUpdate.localPath = targetDir.path;
          await isar.collection<db_models.MushafMetadata>().put(mToUpdate);
          
          // تحديث القائمة فوراً
          await _init();
        }
      });
    } catch (e) {
      debugPrint("Download Error: $e");
    } finally {
      _isDownloading = false;
      _currentDownloadingId = null;
      notifyListeners();
    }
  }
}
