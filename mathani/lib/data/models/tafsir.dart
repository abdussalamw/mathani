import 'package:isar/isar.dart';

part 'tafsir.g.dart';

@collection
class Tafsir {
  Id id = Isar.autoIncrement;

  @Index()
  int surahNumber = 1;
  
  @Index()
  int ayahNumber = 1;

  String tafsirName = ''; // e.g., 'muyassar', 'saadi'
  String text = '';
}
