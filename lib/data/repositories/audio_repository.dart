import '../../domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  @override
  Future<void> playAyah(int surah, int ayah) async {
    // Logic to play audio
  }
  
  @override
  Future<void> stop() async {
    // Logic to stop
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}
}
