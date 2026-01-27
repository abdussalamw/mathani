import 'package:isar/isar.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/collections.dart';

class QuranLocalDataSource {
  Future<List<Surah>> getSurahs() async {
    final isar = await IsarService.instance.db;
    return await isar.collection<Surah>().where().findAll();
  }
}
