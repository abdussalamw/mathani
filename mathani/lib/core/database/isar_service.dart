import 'package:isar/isar.dart';
import 'dart:io'; // For File operations
import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:path_provider/path_provider.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/core/database/collections.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;
  
  Isar? _isar;
  Isar get isar {
    if (_isar == null) {
      throw StateError('Isar database has not been initialized. Call init() first and check for errors.');
    }
    return _isar!;
  }
  
  IsarService._internal();
  
    // تهيئة قاعدة البيانات
    Future<void> init() async {
      // 1. التحقق مما إذا كانت قاعدة البيانات مفتوحة بالفعل
      if (_isar != null && _isar!.isOpen) return;
      
      final existing = Isar.getInstance();
      if (existing != null) {
        _isar = existing;
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      
      try {
        _isar = await Isar.open(
          [
            SurahSchema,
            AyahSchema,
            UserSettingsSchema,
            MushafMetadataSchema,
            AudioCacheSchema,
            ReadingProgressSchema,
            BookmarkSchema,
            TafsirSchema,
          ],
          directory: dir.path,
          inspector: !kReleaseMode,
        );
      } catch (e) {
        debugPrint('Failed to open Isar: $e. Clearning DB...');
        
        // المحاولة الأولى: مسح محتويات المجلد إذا فشل الفتح بسبب الـ Schema
        try {
          // نتأكد من إغلاق أي نسخة عالقة (Ghost instance) إذا وجدت
          final ghost = Isar.getInstance();
          if (ghost != null) await ghost.close(deleteFromDisk: true);
 
          final dbFile = File('${dir.path}/default.isar');
          final lockFile = File('${dir.path}/default.isar.lock');
          if (await dbFile.exists()) await dbFile.delete();
          if (await lockFile.exists()) await lockFile.delete();
        } catch (_) {}
 
        // المحاولة الثانية
        _isar = await Isar.open(
          [
            SurahSchema,
            AyahSchema,
            UserSettingsSchema,
            MushafMetadataSchema,
            AudioCacheSchema,
            ReadingProgressSchema,
            BookmarkSchema,
            TafsirSchema,
          ],
          directory: dir.path,
          inspector: !kReleaseMode,
        );
      }
    }
  
  // إغلاق قاعدة البيانات
  Future<void> close() async {
    await isar.close();
  }
  
  // مسح جميع البيانات (للتطوير)
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}