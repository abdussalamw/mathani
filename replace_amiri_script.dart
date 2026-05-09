import 'dart:io';

void main() {
  final files = [
    'c:/Projects/New app/mathani/lib/presentation/widgets/page_line_widget.dart',
    'c:/Projects/New app/mathani/lib/presentation/widgets/dialogs/ayah_content_sheet.dart',
    'c:/Projects/New app/mathani/lib/presentation/widgets/audio_player_sheet.dart',
    'c:/Projects/New app/mathani/lib/presentation/screens/tafsir/tafsir_screen.dart',
    'c:/Projects/New app/mathani/lib/presentation/screens/splash/splash_screen.dart',
    'c:/Projects/New app/mathani/lib/presentation/screens/settings/general_settings_screen.dart',
    'c:/Projects/New app/mathani/lib/presentation/providers/settings_provider.dart',
    'c:/Projects/New app/mathani/lib/core/database/collections.dart',
  ];

  for (final path in files) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        var content = file.readAsStringSync();
        
        if (path.contains('ayah_content_sheet.dart') || path.contains('tafsir_screen.dart')) {
            content = content.replaceAll("'Amiri'", "'Tajawal'");
        } else if (path.contains('page_line_widget.dart')) {
            content = content.replaceAll("'Amiri'", "'KFGQPC_HAFS'");
        } else {
            content = content.replaceAll("'Amiri'", "'Tajawal'");
            content = content.replaceAll('"Amiri"', '"Tajawal"');
        }
        
        file.writeAsStringSync(content);
        print('Updated $path');
      }
    } catch (e) {
      print('Error updating $path: $e');
    }
  }
}
