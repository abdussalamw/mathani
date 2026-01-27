import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../core/database/collections.dart';
import '../core/database/isar_service.dart';

class MushafMetadataProvider extends ChangeNotifier {
  List<MushafMetadata> _availableMushafs = [];
  List<MushafMetadata> get availableMushafs => _availableMushafs;

  String? _currentMushafId;
  String get currentMushafId => _currentMushafId ?? 'madani_font_v1';

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Download State
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

      // 1. Load Metadata from DB
      var mushafs = await isar.mushafMetadatas.where().findAll();

      // 2. Clear and Re-seed if empty or outdated (Ensures data exists)
      if (mushafs.isEmpty) {
        await _seedDefaultMushafs(isar);
        mushafs = await isar.mushafMetadatas.where().findAll();
      }

      // 3. Get current setting
      final settings = await isar.userSettings.where().findFirst();
      if (settings != null) {
        _currentMushafId = settings.selectedMushafId;
      } else {
        _currentMushafId = 'madani_font_v1';
      }

      _availableMushafs = mushafs;
    } catch (e) {
      debugPrint('Error initializing MushafProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _init();
  }

  Future<void> _seedDefaultMushafs(Isar isar) async {
    final defaults = [
      MushafMetadata()
        ..identifier = 'madani_font_v1'
        ..nameArabic = 'مصحف المدينة (نص - V1)'
        ..nameEnglish = 'Madani (Font - V1)'
        ..type = 'font'
        ..isDownloaded = true, 
        
      MushafMetadata()
        ..identifier = 'qcf2_v4_woff2'
        ..nameArabic = 'مصحف المدينة (QCF2 - V4)'
        ..nameEnglish = 'Madani (QCF2 V4 - WOFF2)'
        ..type = 'font_v2' // Distinguish from old font
        ..baseUrl = 'https://github.com/abdussalamw/mathani/releases/download/v1.0-assets/quran_fonts_qfc4.zip'
        ..isDownloaded = false,

      MushafMetadata()
              ..identifier = 'madani_images_15lines'
              ..nameArabic = 'مصحف المدينة (صور - 15 سطر)'
              ..nameEnglish = 'Madani (Images - 15 Lines)'
              ..type = 'image'
              ..baseUrl = 'https://android.quran.com/data/width_1024/page'
              ..isDownloaded = false,
    ];

    await isar.writeTxn(() async {
      // Upsert (Insert or Update based on ID if we had fixed IDs, but here we query by identifier)
      for (final m in defaults) {
         final existing = await isar.mushafMetadatas.filter().identifierEqualTo(m.identifier).findFirst();
         if (existing == null) {
           await isar.mushafMetadatas.put(m);
         }
      }
    });
  }

  Future<void> setMushaf(String identifier) async {
    final isar = await IsarService.instance.db;
    
    // Check if needs download
    final mushaf = _availableMushafs.firstWhere((m) => m.identifier == identifier);
    if (!mushaf.isDownloaded && mushaf.baseUrl != null) {
       // Cannot select if not downloaded! (UI should handle this, but safeguard here)
       // Optionally trigger download?
       debugPrint('Mushaf not downloaded yet');
       return;
    }

    await isar.writeTxn(() async {
      final settings = await isar.userSettings.where().findFirst() ?? UserSettings();
      settings.selectedMushafId = identifier;
      await isar.userSettings.put(settings);
    });

    _currentMushafId = identifier;
    notifyListeners();
  }

  Future<void> downloadMushaf(String identifier) async {
    final mushaf = _availableMushafs.firstWhere((m) => m.identifier == identifier);
    if (mushaf.baseUrl == null) return;
    if (_isDownloading) return; // Prevent concurrent downloads

    _isDownloading = true;
    _currentDownloadingId = identifier;
    _downloadProgress = 0;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${dir.path}/mushaf_assets/$identifier');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      final zipPath = '${targetDir.path}/assets.zip';
      
      debugPrint('Starting download from: ${mushaf.baseUrl}');
      
      // 1. Download Zip
      await Dio().download(
        mushaf.baseUrl!,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
             _downloadProgress = received / total;
             notifyListeners(); // Throttle this in real app
          }
        },
      );

      debugPrint('Download complete. Unzipping...');

      // 2. Unzip
       final bytes = File(zipPath).readAsBytesSync();
       final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${targetDir.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }
      
      // Cleanup Zip
      File(zipPath).deleteSync();
      debugPrint('Unzip complete.');

      // 3. Update DB
       final isar = await IsarService.instance.db;
       await isar.writeTxn(() async {
          // Re-fetch to ensure we have the Isar object attached
          final mToUpdate = await isar.mushafMetadatas.filter().identifierEqualTo(identifier).findFirst();
          if (mToUpdate != null) {
             mToUpdate.isDownloaded = true;
             mToUpdate.localPath = targetDir.path;
             await isar.mushafMetadatas.put(mToUpdate);
             
             // Update Local List in memory
             final index = _availableMushafs.indexWhere((m) => m.identifier == identifier);
             if (index != -1) {
               _availableMushafs[index] = mToUpdate;
             }
          }
       });

    } catch (e) {
      debugPrint("Download Error: $e");
      // TODO: Expose error state
    } finally {
      _isDownloading = false;
      _currentDownloadingId = null;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }
  
   Future<void> deleteMushaf(String identifier) async {
      // Implement delete logic if needed
       final isar = await IsarService.instance.db;
       await isar.writeTxn(() async {
          final mToUpdate = await isar.mushafMetadatas.filter().identifierEqualTo(identifier).findFirst();
          if (mToUpdate != null) {
             mToUpdate.isDownloaded = false;
             mToUpdate.localPath = null;
             await isar.mushafMetadatas.put(mToUpdate);
             
            // Delete files physically
            final dir = await getApplicationDocumentsDirectory();
            final targetDir = Directory('${dir.path}/mushaf_assets/$identifier');
            if (await targetDir.exists()) {
              await targetDir.delete(recursive: true);
            }
             
             // Update memory
             final index = _availableMushafs.indexWhere((m) => m.identifier == identifier);
             if (index != -1) {
               _availableMushafs[index] = mToUpdate;
             }
          }
       });
       notifyListeners();
  }
}
