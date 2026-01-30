import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;
  final String textSimple;
  final int page;
  final int juz;
  final int hizbQuarter;
  final bool isBookmarked;

  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    required this.textSimple,
    required this.page,
    required this.juz,
    required this.hizbQuarter,
    this.isBookmarked = false,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber, textUthmani, textSimple, page, juz, hizbQuarter, isBookmarked];
}
