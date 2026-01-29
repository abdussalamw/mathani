import 'package:get_it/get_it.dart';

import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/metadata_repository.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/metadata_repository.dart';

import '../../domain/usecases/get_all_surahs_usecase.dart';
import '../../domain/usecases/get_ayahs_usecase.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../domain/usecases/get_metadata_usecase.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // UseCases
  sl.registerLazySingleton(() => GetAllSurahsUseCase(sl()));
  sl.registerLazySingleton(() => GetAyahsForSurahUseCase(sl()));
  sl.registerLazySingleton(() => GetAyahsForPageUseCase(sl()));
  sl.registerLazySingleton(() => GetAllAyahsUseCase(sl()));
  sl.registerLazySingleton(() => GetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SaveSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetSurahPageMapUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<QuranRepository>(() => QuranRepositoryImpl());
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  sl.registerLazySingleton<MetadataRepository>(() => MetadataRepositoryImpl());

  // Data Sources (Optional, implicit in Repositories for now or can be extracted)
  // sl.registerLazySingleton<QuranRemoteDataSource>(() => QuranRemoteDataSource());
}
