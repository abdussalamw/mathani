import '../../domain/entities/user_settings.dart' as entity;
import '../../core/database/collections.dart' as model;

class SettingsMapper {
  static entity.UserSettings toEntity(model.UserSettings modelSettings) {
    return entity.UserSettings(
      isDarkMode: modelSettings.isDarkMode,
      fontSize: modelSettings.fontSize,
      selectedMushafId: modelSettings.selectedMushafId,
      defaultReciterId: modelSettings.defaultReciter,
      defaultTafsirId: modelSettings.defaultTafsir,
    );
  }

  static model.UserSettings toModel(entity.UserSettings entitySettings) {
    return model.UserSettings()
      ..isDarkMode = entitySettings.isDarkMode
      ..fontSize = entitySettings.fontSize
      ..selectedMushafId = entitySettings.selectedMushafId
      ..defaultReciter = entitySettings.defaultReciterId
      ..defaultTafsir = entitySettings.defaultTafsirId;
  }
}
