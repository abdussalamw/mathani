
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../core/database/collections.dart';
import '../core/database/isar_service.dart';

class MushafMetadataProvider extends ChangeNotifier {
  // القائمة الثابتة كـ Fallback في حال فشل الداتابيز
  final List<MushafMetadata> _fallbackMushafs = [
    MushafMetadata()
      ..identifier = 'madani_font_v1'
      ..nameArabic = 'مصحف المدينة (نص رقمي)'
      ..nameEnglish = 'Madani (Font - V1)'
      ..type = 'font'
      ..isDownloaded = true, 
      
    MushafMetadata()
      ..identifier = 'qcf2_v4_woff2'
      ..nameArabic = 'مصحف المدينة (QCF2 - V4)'
      ..nameEnglish = 'Madani (QCF2 V4)'
      ..type = 'font_v2'
      ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/quran_fonts_qfc4.zip'
      ..isDownloaded = false,

    MushafMetadata()
      ..identifier = 'madani_images_15lines'
      ..nameArabic = 'مصحف المدينة (صور)'
      ..nameEnglish = 'Madani (Images)'
      ..type = 'image'
      ..baseUrl = 'https://android.quran.com/data/width_1024/page'
      ..isDownloaded = false,
  ];

  List<MushafMetadata> _availableMushafs = [];
  List<MushafMetadata> get availableMushafs => _availableMushafs.isNotEmpty ? _availableMushafs : _fallbackMushafs;

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
      final isar = await IsarService.instance.db;
      
      // جلب البيانات من الداتا بيز
      var mushafs = await isar.collection<MushafMetadata>().where().findAll();

      // إذا كانت فارغة تماماً، نحاول زرعها
      if (mushafs.isEmpty) {
        await _seedDefaultMushafs(isar);
        mushafs = await isar.collection<MushafMetadata>().where().findAll();
      }

      // تحديث القائمة في الذاكرة
      if (mushafs.isNotEmpty) {
        _availableMushafs = mushafs;
      } else {
        // إذا فشل كل شيء، نستخدم القائمة الثابتة
        _availableMushafs = _fallbackMushafs;
      }

      final settings = await isar.collection<UserSettings>().where().findFirst();
      if (settings != null) {
        _currentMushafId = settings.selectedMushafId;
      } else {
        _currentMushafId = 'madani_font_v1';
      }
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
           await isar.collection<MushafMetadata>().put(mushaf);
        }
      });
    } catch (e) {
      debugPrint('Seeding failed: $e');
    }
  }

  Future<void> setMushaf(String identifier) async {
    final isar = await IsarService.instance.db;
    await isar.writeTxn(() async {
      final settings = await isar.collection<UserSettings>().where().findFirst() ?? UserSettings();
      settings.selectedMushafId = identifier;
      await isar.collection<UserSettings>().put(settings);
    });
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

      final isar = await IsarService.instance.db;
      await isar.writeTxn(() async {
        final mToUpdate = await isar.collection<MushafMetadata>().filter().identifierEqualTo(identifier).findFirst();
        if (mToUpdate != null) {
          mToUpdate.isDownloaded = true;
          mToUpdate.localPath = targetDir.path;
          await isar.collection<MushafMetadata>().put(mToUpdate);
          
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
