abstract class AudioRepository {
  Future<void> playAyah(int surah, int ayah);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
}
