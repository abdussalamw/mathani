import 'package:isar/isar.dart';

part 'juz.g.dart';

@collection
class Juz {
  Id id = Isar.autoIncrement;
  
  @Index()
  int number = 1;
  
  int startSurah = 1;
  int startAyah = 1;
  int endSurah = 1;
  int endAyah = 1;
}
