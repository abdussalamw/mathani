import '../../domain/entities/surah.dart' as entity;
import '../../core/database/collections.dart' as model;

class SurahMapper {
  static entity.Surah toEntity(model.Surah modelSurah) {
    return entity.Surah(
      number: modelSurah.number,
      nameArabic: modelSurah.nameArabic,
      nameEnglish: modelSurah.nameEnglish,
      revelationType: modelSurah.revelation == model.RevelationType.meccan 
          ? entity.RevelationType.meccan 
          : entity.RevelationType.medinan,
      numberOfAyahs: modelSurah.numberOfAyahs,
      startPage: modelSurah.page,
      startJuz: modelSurah.juzNumber,
    );
  }

  static model.Surah toModel(entity.Surah entitySurah) {
    return model.Surah()
      ..number = entitySurah.number
      ..nameArabic = entitySurah.nameArabic
      ..nameEnglish = entitySurah.nameEnglish
      ..revelation = entitySurah.revelationType == entity.RevelationType.meccan
          ? model.RevelationType.meccan
          : model.RevelationType.medinan
      ..numberOfAyahs = entitySurah.numberOfAyahs
      ..page = entitySurah.startPage
      ..juzNumber = entitySurah.startJuz;
  }

  static List<entity.Surah> toEntityList(List<model.Surah> models) {
    return models.map(toEntity).toList();
  }
}
