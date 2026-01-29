import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;
  
  late AudioPlayer _audioPlayer;
  
  AudioService._internal() {
    _audioPlayer = AudioPlayer();
  }
  
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  Future<void> setUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
    } catch (e) {
      print('Error loading audio: $e');
      rethrow;
    }
  }
  
  Future<void> play() async {
    await _audioPlayer.play();
  }
  
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}
