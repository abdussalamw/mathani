import '../../core/database/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/database/collections.dart' as model;
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/user_settings.dart';
import '../../core/errors/failures.dart';


class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Either<Failure, UserSettings>> getSettings() async {
    try {
      final isar = IsarService.instance.isar;
      final settings = await isar.collection<model.UserSettings>().where().findFirst();
      
      if (settings != null) {
        // Manual mapping to Entity
        return Right(UserSettings(
          isDarkMode: settings.isDarkMode,
          fontSize: settings.fontSize,
          selectedMushafId: settings.selectedMushafId,
          defaultReciterId: settings.defaultReciter,
          defaultTafsirId: settings.defaultTafsir,
        ));
      } else {
        return Right(UserSettings.defaults());
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(UserSettings settings) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final currentSettings = await isar.collection<model.UserSettings>().where().findFirst() ?? model.UserSettings();
        
        // Manual mapping to Model
        currentSettings.isDarkMode = settings.isDarkMode;
        currentSettings.fontSize = settings.fontSize;
        currentSettings.selectedMushafId = settings.selectedMushafId;
        currentSettings.defaultReciter = settings.defaultReciterId;
        currentSettings.defaultTafsir = settings.defaultTafsirId;
          
        await isar.collection<model.UserSettings>().put(currentSettings);
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
