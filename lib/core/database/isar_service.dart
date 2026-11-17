import 'package:isar_community/isar.dart';

import 'dart:io'; // For File operations

import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:path_provider/path_provider.dart';
import 'package:mathani/core/database/collections.dart';
import 'package:mathani/data/models/recitation_session.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;
  static const schemas = [
    SurahSchema,
    AyahSchema,
    UserSettingsSchema,
    MushafMetadataSchema,
    AudioCacheSchema,
    ReadingProgressSchema,
    BookmarkSchema,
    TafsirSchema,
    RecitationSessionSchema,
  ];

  Isar? _isar;
  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError(
        'Isar database has not been initialized. Call init() first and check for errors.',
      );
    }
    return _isar!;
  }

  IsarService._internal();

  // تهيئة قاعدة البيانات
  Future<void> init({String? directory}) async {
    // 1. التحقق مما إذا كانت قاعدة البيانات مفتوحة بالفعل
    if (_isar != null && _isar!.isOpen) return;

    final existing = Isar.getInstance();
    if (existing != null) {
      _isar = existing;
      return;
    }

    final directoryPath =
        directory ?? (await getApplicationDocumentsDirectory()).path;
    final dbFile = File('$directoryPath/default.isar');
    final backupFile = File(
      '$directoryPath/default.isar.before-community-3.4.1',
    );
    if (await dbFile.exists() && !await backupFile.exists()) {
      await dbFile.copy(backupFile.path);
    }

    try {
      _isar = await Isar.open(
        schemas,
        directory: directoryPath,
        inspector: !kReleaseMode,
      );
    } catch (e) {
      debugPrint('Failed to open Isar; existing data was preserved: $e');
      rethrow;
    }
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final database = _isar;
    if (database != null && database.isOpen) await database.close();
    _isar = null;
  }

  // مسح جميع البيانات (للتطوير)
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
