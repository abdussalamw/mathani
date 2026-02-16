
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:path_provider/path_provider.dart';

import '../../core/database/collections.dart' as db_models; // Alias
import '../../core/database/isar_service.dart';
import '../../data/services/mushaf_downloader_service.dart' as db_models; // Using alias to access service
import '../../core/di/service_locator.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      ..baseUrl = null  // Bundled assets
      ..localPath = 'assets/fonts/qcf2'
      ..isDownloaded = true,

    // 2. Madani Old Script (Fonts - QPC V1)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_old_v1')
      ..identifier = 'madani_old_v1'
      ..nameArabic = 'مصحف المدينة ـ الرسم القديم'
      ..nameEnglish = 'Madani Mushaf - Old Script'
      ..type = 'page_font' // New type for QPC V1
      ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/qpc_v1_by_page.tar.bz2'
      ..localPath = 'mushafs/madani_old_v1' // Extracted path
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

    // 3. Digital (Hidden/Fallback)
    db_models.MushafMetadata()
      ..id = db_models.fastHash('madani_font_v1')
      ..identifier = 'madani_font_v1'
      ..nameArabic = 'المصحف الإلكتروني (نص رقمي)'
      ..nameEnglish = 'Digital Mushaf (System Text)'
      ..type = 'digital'
      ..isDownloaded = true, 
  ];

  List<db_models.MushafMetadata> _availableMushafs = [];
  // Filter out 'digital' type from the UI list as requested
  List<db_models.MushafMetadata> get availableMushafs => _availableMushafs.isNotEmpty 
      ? _availableMushafs.where((m) => m.type != 'digital').toList() 
      : _fallbackMushafs.where((m) => m.type != 'digital').toList();

  String? _currentMushafId;
  // Default to 'qcf2_v4_woff2' (Madani New Script)
  String get currentMushafId => _currentMushafId ?? 'qcf2_v4_woff2';
  
  String get currentMushafType {
    if (_currentMushafId == null) return 'digital';
    
    // Find in available list
    try {
      final mushaf = _availableMushafs.firstWhere(
        (m) => m.identifier == _currentMushafId
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

      // تزامن البيانات: تأكد من أن كل المصاحف المعرفة في الكود موجودة ومحدثة في قاعدة البيانات
      await isar.writeTxn(() async {
        for (var fallback in _fallbackMushafs) {
          final existing = mushafs.firstWhere(
            (m) => m.identifier == fallback.identifier,
            orElse: () => fallback, // يرجع fallback نفسها علامة على عدم الوجود (للمقارنة بالمعرف)
          );

          // إذا لم يكن موجوداً، أو إذا نحتاج لتحديث الروابط
          // نلاحظ هنا المقارنة بالـ identifier لأن fallback المرجع هو كائن جديد
          final isNew = !mushafs.any((m) => m.identifier == fallback.identifier);
          
          if (isNew) {
            await isar.collection<db_models.MushafMetadata>().put(fallback);
          } else {
            // تحديث البيانات الأساسية (URL, Name, e.g.) للموجود
             final existingItem = mushafs.firstWhere((m) => m.identifier == fallback.identifier);
             
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
      mushafs = await isar.collection<db_models.MushafMetadata>().where().findAll();

      // تحديث القائمة في الذاكرة
      if (mushafs.isNotEmpty) {
        _availableMushafs = mushafs;
      } else {
        _availableMushafs = _fallbackMushafs;
      }

      final result = await _settingsRepository.getSettings();
      result.fold(
        (failure) => _currentMushafId = 'qcf2_v4_woff2',
        (settings) {
           _currentMushafId = settings.selectedMushafId ?? 'qcf2_v4_woff2';
           // FORCE MIGRATION: If old digital or system font is selected, switch to qcf2
           if (_currentMushafId == 'madani_font_v1' || _currentMushafId == 'digital') {
             _currentMushafId = 'qcf2_v4_woff2';
             _saveSettings(); // Persist the fix
           }
        }, 
      );
    } catch (e) {
      debugPrint('MushafProvider Error: $e');
      _availableMushafs = _fallbackMushafs;
      _currentMushafId = 'qcf2_v4_woff2';
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

  Future<void> downloadMushaf(String identifier) async {
    final mushaf = _availableMushafs.firstWhere(
      (m) => m.identifier == identifier,
      orElse: () => _availableMushafs.first
    );

    if (mushaf.baseUrl == null) return;

    _isDownloading = true;
    _currentDownloadingId = identifier;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetPath = '${appDir.path}/mushafs/$identifier';
      
      // Use the new downloader service
      await db_models.MushafDownloaderService.downloadAndExtract(
        url: mushaf.baseUrl!,
        destinationPath: targetPath,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      // Update metadata
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        mushaf.isDownloaded = true;
        mushaf.localPath = targetPath;
        
        // Update in DB
        final existing = await isar.collection<db_models.MushafMetadata>()
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

  Future<void> _saveSettings() async {
    if (_currentMushafId == null) return;
    try {
      final result = await _settingsRepository.getSettings();
      final currentSettings = result.fold(
        (l) => UserSettings.defaults(), 
        (r) => r
      );
      final newSettings = currentSettings.copyWith(selectedMushafId: _currentMushafId);
      await _settingsRepository.saveSettings(newSettings);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
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
