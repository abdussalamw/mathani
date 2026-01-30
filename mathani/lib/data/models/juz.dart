import 'package:isar/isar.dart';

part 'juz.g.dart';

@collection
class Juz {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int number;
  
  late int startSurah;
  late int startAyah;
  late int endSurah;
  late int endAyah;
}
