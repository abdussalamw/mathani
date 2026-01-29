import '../../domain/entities/ayah.dart' as entity;
import '../../core/database/collections.dart' as model;

class AyahMapper {
  static entity.Ayah toEntity(model.Ayah modelAyah) {
    return entity.Ayah(
      surahNumber: modelAyah.surahNumber,
      ayahNumber: modelAyah.ayahNumber,
      textUthmani: modelAyah.textUthmani,
      textSimple: modelAyah.textSimple,
      page: modelAyah.page,
      juz: modelAyah.juz,
      hizbQuarter: modelAyah.hizbQuarter,
      isBookmarked: modelAyah.isBookmarked,
    );
  }

  static model.Ayah toModel(entity.Ayah entityAyah) {
    return model.Ayah()
      ..surahNumber = entityAyah.surahNumber
      ..ayahNumber = entityAyah.ayahNumber
      ..textUthmani = entityAyah.textUthmani
      ..textSimple = entityAyah.textSimple
      ..page = entityAyah.page
      ..juz = entityAyah.juz
      ..hizbQuarter = entityAyah.hizbQuarter
      ..isBookmarked = entityAyah.isBookmarked;
  }
  
  static List<entity.Ayah> toEntityList(List<model.Ayah> models) {
    return models.map(toEntity).toList();
  }
}
