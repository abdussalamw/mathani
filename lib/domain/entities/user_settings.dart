import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final bool isDarkMode;
  final double fontSize;
  final String selectedMushafId;
  final String defaultReciterId;
  final String defaultTafsirId;

  const UserSettings({
    required this.isDarkMode,
    required this.fontSize,
    required this.selectedMushafId,
    required this.defaultReciterId,
    required this.defaultTafsirId,
  });

  // Factory for default settings
  factory UserSettings.defaults() {
    return const UserSettings(
      isDarkMode: false,
      fontSize: 28.0,
      selectedMushafId: 'madani_font_v1',
      defaultReciterId: 'minshawi_murattal',
      defaultTafsirId: 'muyassar',
    );
  }

  UserSettings copyWith({
    bool? isDarkMode,
    double? fontSize,
    String? selectedMushafId,
    String? defaultReciterId,
    String? defaultTafsirId,
  }) {
    return UserSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      selectedMushafId: selectedMushafId ?? this.selectedMushafId,
      defaultReciterId: defaultReciterId ?? this.defaultReciterId,
      defaultTafsirId: defaultTafsirId ?? this.defaultTafsirId,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, fontSize, selectedMushafId, defaultReciterId, defaultTafsirId];
}
