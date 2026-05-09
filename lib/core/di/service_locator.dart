import 'package:get_it/get_it.dart';

import '../../domain/repositories/quran_repository.dart';
import '../../data/repositories/quran_repository.dart'; // Contains Impl
import '../../data/repositories/reciter_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/repositories/settings_repository.dart'; // Added Interface
import '../../data/data_sources/local/quran_local_data_source.dart';

import '../../domain/usecases/get_surah_list.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Data Sources
  sl.registerLazySingleton(() => QuranLocalDataSource.instance);
  
  // UseCases
  sl.registerLazySingleton(() => GetAllSurahsUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  sl.registerLazySingleton<QuranRepository>(() => QuranRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<ReciterRepository>(() => ReciterRepositoryImpl());
}
