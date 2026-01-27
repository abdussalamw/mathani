import '../../core/database/isar_service.dart';
import '../../core/database/collections.dart';
import 'package:isar/isar.dart';

import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  Future<UserSettings?> getSettings() async {
    final isar = await IsarService.instance.db;
    return await isar.collection<UserSettings>().where().findFirst();
  }

  Future<void> saveSettings(UserSettings settings) async {
    final isar = await IsarService.instance.db;
    await isar.writeTxn(() async {
      await isar.collection<UserSettings>().put(settings);
    });
  }
}
