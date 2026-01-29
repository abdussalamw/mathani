import '../../core/database/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/database/collections.dart' as model;
import '../../core/database/isar_service.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/core/errors/failures.dart';
import '../mappers/settings_mapper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Either<Failure, UserSettings>> getSettings() async {
    try {
      final isar = await IsarService.instance.db;
      final settings = await isar.collection<model.UserSettings>().where().findFirst();
      
      if (settings != null) {
        return Right(SettingsMapper.toEntity(settings));
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
      final isar = await IsarService.instance.db;
      await isar.writeTxn(() async {
        final currentSettings = await isar.collection<model.UserSettings>().where().findFirst() ?? model.UserSettings();
        
        final newModel = SettingsMapper.toModel(settings)
          ..id = currentSettings.id; // Preserve ID
          
        await isar.collection<model.UserSettings>().put(newModel);
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
