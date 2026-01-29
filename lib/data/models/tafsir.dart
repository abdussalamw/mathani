import 'package:isar/isar.dart';

part 'tafsir.g.dart';

@collection
class Tafsir {
  Id id = Isar.autoIncrement;

  @Index()
  late int surahNumber;
  
  @Index()
  late int ayahNumber;

  late String tafsirName; // e.g., 'muyassar', 'saadi'
  late String text;
}
