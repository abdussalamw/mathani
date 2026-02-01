import '../../domain/repositories/audio_repository.dart';
import '../../core/services/audio_service.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioService _audioService = AudioService();
  
  // Base URL for audio (Alafasy 128kbps as an example source)
  // https://everyayah.com/data/Alafasy_128kbps/001001.mp3
  final String _baseUrl = 'https://everyayah.com/data/Alafasy_128kbps';
  
  @override
  Future<void> playAyah(int surah, int ayah) async {
    final String surahStr = surah.toString().padLeft(3, '0');
    final String ayahStr = ayah.toString().padLeft(3, '0');
    final String url = '$_baseUrl/$surahStr$ayahStr.mp3';
    
    try {
      await _audioService.play(url);
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }
  
  @override
  Future<void> stop() async {
    await _audioService.stop();
  }

  @override
  Future<void> pause() async {
    await _audioService.pause();
  }

  @override
  Future<void> resume() async {
    await _audioService.resume();
  }
}
