import 'package:equatable/equatable.dart';

enum RevelationType { meccan, medinan }

class Surah extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final RevelationType revelationType;
  final int numberOfAyahs;
  final int startPage;
  final int startJuz;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.startPage,
    required this.startJuz,
  });

  @override
  List<Object?> get props => [number, nameArabic, nameEnglish, revelationType, numberOfAyahs, startPage, startJuz];
}
