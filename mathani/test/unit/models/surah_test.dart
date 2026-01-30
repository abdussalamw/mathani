import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/database/collections.dart';

void main() {
  group('Surah Model Tests', () {
    test('should create Surah object correctly', () {
      // Arrange
      final surah = Surah()
        ..number = 1
        ..nameArabic = 'الفاتحة'
        ..nameEnglish = 'Al-Fatihah'
        ..numberOfAyahs = 7;
      
      // Act & Assert
      expect(surah.number, 1);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.numberOfAyahs, 7);
    });
  });
}
