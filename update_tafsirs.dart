import 'dart:io';

void main() {
  void replaceInFile(String path, String from, String to) {
    try {
      var file = File(path);
      if (!file.existsSync()) return;
      var content = file.readAsStringSync();
      content = content.replaceAll(from, to);
      file.writeAsStringSync(content);
      print('Updated $path');
    } catch (e) {
      print('Failed to update $path: $e');
    }
  }

  replaceInFile('c:/Projects/New app/mathani/lib/core/database/collections.dart', 
    "String defaultTafsir = 'muyassar';", 
    "String defaultTafsir = 'w-moyassar';");

  replaceInFile('c:/Projects/New app/mathani/lib/domain/entities/user_settings.dart', 
    "defaultTafsirId: 'muyassar',", 
    "defaultTafsirId: 'w-moyassar',");

  replaceInFile('c:/Projects/New app/mathani/lib/presentation/screens/settings/settings_screen.dart', 
    "settings.defaultTafsir == 'muyassar' ? 'التفسير الميسر' : settings.defaultTafsir", 
    "settings.defaultTafsir == 'w-moyassar' || settings.defaultTafsir == 'muyassar' ? 'التفسير الميسر للقرآن الكريم' : settings.defaultTafsir");

  replaceInFile('c:/Projects/New app/mathani/lib/presentation/screens/settings/settings_screen.dart', 
    "{'id': 'w-moyassar', 'name': 'التفسير الميسر'},", 
    "{'id': 'w-moyassar', 'name': 'التفسير الميسر للقرآن الكريم'},");

  replaceInFile('c:/Projects/New app/mathani/lib/presentation/screens/tafsir/tafsir_screen.dart', 
    "DropdownMenuItem(value: 'w-moyassar', child: Text('التفسير الميسر')),", 
    "DropdownMenuItem(value: 'w-moyassar', child: Text('التفسير الميسر للقرآن الكريم')),");

  var providerFile = File('c:/Projects/New app/mathani/lib/presentation/providers/surah_content_provider.dart');
  if (providerFile.existsSync()) {
    var providerContent = providerFile.readAsStringSync();
    if (!providerContent.contains("if (slug == 'muyassar') slug = 'w-moyassar';")) {
      providerContent = providerContent.replaceAll('''  void setTafsirSlug(String slug, {bool shouldNotify = false}) {
    _selectedTafsirSlug = slug;''', 
      '''  void setTafsirSlug(String slug, {bool shouldNotify = false}) {
    if (slug == 'muyassar') slug = 'w-moyassar';
    _selectedTafsirSlug = slug;''');
      providerFile.writeAsStringSync(providerContent);
      print('Updated surah_content_provider.dart');
    }
  }

  print('Done.');
}
