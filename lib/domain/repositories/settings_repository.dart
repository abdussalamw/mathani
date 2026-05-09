import 'package:fpdart/fpdart.dart';
import '../entities/user_settings.dart';
import 'package:mathani/core/errors/failures.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> getSettings();
  Future<Either<Failure, void>> saveSettings(UserSettings settings);
}
