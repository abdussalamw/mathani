
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  Future<void> playAyah(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _playbackSpeed = speed;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
