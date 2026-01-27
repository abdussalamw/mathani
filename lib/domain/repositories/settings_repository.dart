import '../../core/database/collections.dart';

abstract class SettingsRepository {
  Future<UserSettings?> getSettings();
  Future<void> saveSettings(UserSettings settings);
}
