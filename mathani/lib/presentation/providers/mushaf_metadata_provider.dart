
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:path_provider/path_provider.dart';

import '../../core/database/collections.dart' as db_models; // Alias
import '../../core/database/isar_service.dart';
import '../../core/di/service_locator.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MushafMetadataProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository = sl<SettingsRepository>();
  
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
      ..baseUrl = null  // الخطوط مضمنة في assets
      ..localPath = 'assets/fonts/qcf2'  // مسار الخطوط المحلية
      ..isDownloaded = true,  // الخطوط مضمنة مسبقاً

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
      // Skip Isar on Web
      if (kIsWeb) {
        _availableMushafs = _fallbackMushafs;
        _currentMushafId = 'madani_font_v1';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final isar = IsarService.instance.isar;
      final prefs = await SharedPreferences.getInstance();
      final areFontsDownloaded = prefs.getBool('fonts_downloaded') ?? false;
      
      // جلب البيانات من الداتا بيز
      var mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll();

      // إذا كانت فارغة تماماً، نحاول زرعها
      if (mushafs.isEmpty) {
        await _seedDefaultMushafs(isar);
        mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll();
      }
      
      // مزامنة حالة التحميل مع SharedPreferences
      if (areFontsDownloaded) {
        await isar.writeTxn(() async {
          final qcf2 = await isar.collection<db_models.MushafMetadata>()
            .filter()
            .identifierEqualTo('qcf2_v4_woff2')
            .findFirst();
          
          if (qcf2 != null && !qcf2.isDownloaded) {
            final appDir = await getApplicationDocumentsDirectory();
            qcf2.isDownloaded = true;
            qcf2.localPath = '${appDir.path}/fonts';
            await isar.collection<db_models.MushafMetadata>().put(qcf2);
          }
        });
        // إعادة جلب البيانات بعد التحديث
        mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll();
      }

      // تحديث القائمة في الذاكرة
      if (mushafs.isNotEmpty) {
        _availableMushafs = mushafs;
      } else {
        // إذا فشل كل شيء، نستخدم القائمة الثابتة
        _availableMushafs = _fallbackMushafs;
      }

      final result = await _settingsRepository.getSettings();
      result.fold(
        (failure) => _currentMushafId = 'madani_font_v1',
        (settings) => _currentMushafId = settings.selectedMushafId,
      );
    } catch (e) {
      debugPrint('MushafProvider Error: $e');
      _availableMushafs = _fallbackMushafs;
      _currentMushafId = 'madani_font_v1';
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
    final result = await _settingsRepository.getSettings();
    
    // We get current settings, modify them, and save
    final currentSettings = result.fold(
      (l) => UserSettings.defaults(), 
      (r) => r
    ); // Fix getOrElse by using fold
    
    final newSettings = currentSettings.copyWith(selectedMushafId: identifier);
    
    await _settingsRepository.saveSettings(newSettings);
    
    _currentMushafId = identifier;
    notifyListeners();
  }

  Future<void> syncWithDownloadedFonts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final areFontsDownloaded = prefs.getBool('fonts_downloaded') ?? false;
      
      if (areFontsDownloaded) {
        final isar = IsarService.instance.isar;
        await isar.writeTxn(() async {
          final qcf2 = await isar.collection<db_models.MushafMetadata>()
            .filter()
            .identifierEqualTo('qcf2_v4_woff2')
            .findFirst();
          
          if (qcf2 != null) {
            final appDir = await getApplicationDocumentsDirectory();
            qcf2.isDownloaded = true;
            qcf2.localPath = '${appDir.path}/fonts';
            await isar.collection<db_models.MushafMetadata>().put(qcf2);
          }
        });
        
        await _init();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }
}
