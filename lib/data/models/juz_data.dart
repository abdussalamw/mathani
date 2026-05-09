/// بيانات الأجزاء الثلاثين
/// كل جزء يحتوي على: رقم الجزء، السورة الأولى، رقم الآية الأولى، رقم الصفحة
class JuzData {
  final int number;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;

  const JuzData({
    required this.number,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
  });
}

/// قائمة الأجزاء الثلاثين
const List<JuzData> juzList = [
  JuzData(number: 1, surahName: 'الفاتحة', surahNumber: 1, ayahNumber: 1, pageNumber: 1),
  JuzData(number: 2, surahName: 'البقرة', surahNumber: 2, ayahNumber: 142, pageNumber: 22),
  JuzData(number: 3, surahName: 'البقرة', surahNumber: 2, ayahNumber: 253, pageNumber: 42),
  JuzData(number: 4, surahName: 'آل عمران', surahNumber: 3, ayahNumber: 93, pageNumber: 62),
  JuzData(number: 5, surahName: 'النساء', surahNumber: 4, ayahNumber: 24, pageNumber: 82),
  JuzData(number: 6, surahName: 'النساء', surahNumber: 4, ayahNumber: 148, pageNumber: 102),
  JuzData(number: 7, surahName: 'المائدة', surahNumber: 5, ayahNumber: 82, pageNumber: 122),
  JuzData(number: 8, surahName: 'الأنعام', surahNumber: 6, ayahNumber: 111, pageNumber: 142),
  JuzData(number: 9, surahName: 'الأعراف', surahNumber: 7, ayahNumber: 88, pageNumber: 162),
  JuzData(number: 10, surahName: 'الأنفال', surahNumber: 8, ayahNumber: 41, pageNumber: 182),
  JuzData(number: 11, surahName: 'التوبة', surahNumber: 9, ayahNumber: 93, pageNumber: 202),
  JuzData(number: 12, surahName: 'هود', surahNumber: 11, ayahNumber: 6, pageNumber: 222),
  JuzData(number: 13, surahName: 'يوسف', surahNumber: 12, ayahNumber: 53, pageNumber: 242),
  JuzData(number: 14, surahName: 'الحجر', surahNumber: 15, ayahNumber: 1, pageNumber: 262),
  JuzData(number: 15, surahName: 'الإسراء', surahNumber: 17, ayahNumber: 1, pageNumber: 282),
  JuzData(number: 16, surahName: 'الكهف', surahNumber: 18, ayahNumber: 75, pageNumber: 302),
  JuzData(number: 17, surahName: 'الأنبياء', surahNumber: 21, ayahNumber: 1, pageNumber: 322),
  JuzData(number: 18, surahName: 'المؤمنون', surahNumber: 23, ayahNumber: 1, pageNumber: 342),
  JuzData(number: 19, surahName: 'الفرقان', surahNumber: 25, ayahNumber: 21, pageNumber: 362),
  JuzData(number: 20, surahName: 'النمل', surahNumber: 27, ayahNumber: 56, pageNumber: 382),
  JuzData(number: 21, surahName: 'العنكبوت', surahNumber: 29, ayahNumber: 46, pageNumber: 402),
  JuzData(number: 22, surahName: 'الأحزاب', surahNumber: 33, ayahNumber: 31, pageNumber: 422),
  JuzData(number: 23, surahName: 'يس', surahNumber: 36, ayahNumber: 28, pageNumber: 442),
  JuzData(number: 24, surahName: 'الزمر', surahNumber: 39, ayahNumber: 32, pageNumber: 462),
  JuzData(number: 25, surahName: 'فصلت', surahNumber: 41, ayahNumber: 47, pageNumber: 482),
  JuzData(number: 26, surahName: 'الأحقاف', surahNumber: 46, ayahNumber: 1, pageNumber: 502),
  JuzData(number: 27, surahName: 'الذاريات', surahNumber: 51, ayahNumber: 31, pageNumber: 522),
  JuzData(number: 28, surahName: 'المجادلة', surahNumber: 58, ayahNumber: 1, pageNumber: 542),
  JuzData(number: 29, surahName: 'الملك', surahNumber: 67, ayahNumber: 1, pageNumber: 562),
  JuzData(number: 30, surahName: 'النبأ', surahNumber: 78, ayahNumber: 1, pageNumber: 582),
];
