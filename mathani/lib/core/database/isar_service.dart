import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/core/database/collections.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;
  
  late Isar _isar;
  Isar get isar => _isar;
  
  IsarService._internal();
  
  // تهيئة قاعدة البيانات
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [
        SurahSchema,
        AyahSchema,
        UserSettingsSchema,
        MushafMetadataSchema,
        AudioCacheSchema,
        ReadingProgressSchema,
      ],
      directory: dir.path,
      inspector: true, // للتطوير فقط
    );
  }
  
  // إغلاق قاعدة البيانات
  Future<void> close() async {
    await _isar.close();
  }
  
  // مسح جميع البيانات (للتطوير)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}