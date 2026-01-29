import 'package:fpdart/fpdart.dart';
import '../repositories/settings_repository.dart';
import '../entities/user_settings.dart';
import 'package:mathani/core/errors/failures.dart';

class GetSettingsUseCase {
  final SettingsRepository repository;
  GetSettingsUseCase(this.repository);

  Future<Either<Failure, UserSettings>> call() {
    return repository.getSettings();
  }
}

class SaveSettingsUseCase {
  final SettingsRepository repository;
  SaveSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call(UserSettings settings) {
    return repository.saveSettings(settings);
  }
}
