
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'collections.dart';

class IsarService {
  static final IsarService instance = IsarService._();
  late Future<Isar> db;

  IsarService._() {
    db = openDB();
  }

  Future<void> init() async {
    await db;
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          SurahSchema,
          AyahSchema,
          TafsirSchema,
          AudioCacheSchema,
          UserSettingsSchema,
          ReadingProgressSchema,
          MushafMetadataSchema,
        ],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
