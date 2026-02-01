import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int? _currentSurah;
  int? _currentAyah;

  final List<Map<String, String>> reciters = [
    {'id': 'Abdul_Basit_Murattal_192kbps', 'name': 'عبد الباسط عبد الصمد (مرتل)'},
    {'id': 'Alafasy_128kbps', 'name': 'مشاري راشد العفاسي'},
    {'id': 'Hussary_128kbps', 'name': 'محمود خليل الحصري'},
    {'id': 'Minshawi_Murattal_128kbps', 'name': 'محمد صديق المنشاوي (مرتل)'},
  ];

  late Map<String, String> _currentReciter;

  bool get isPlaying => _isPlaying;
  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  Map<String, String> get currentReciter => _currentReciter;

  AudioProvider() {
    _currentReciter = reciters[0];
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _currentSurah = null;
        _currentAyah = null;
      }
      notifyListeners();
    });
  }

  Future<void> playAyah(int surah, int ayah) async {
    try {
      _currentSurah = surah;
      _currentAyah = ayah;
      
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      
      final url = 'https://everyayah.com/data/${_currentReciter['id']}/$s$a.mp3';
      
      await _player.setUrl(url);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Audio Error: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  void setReciter(Map<String, String> reciter) {
    _currentReciter = reciter;
    notifyListeners();
    if (_currentSurah != null && _currentAyah != null) {
      playAyah(_currentSurah!, _currentAyah!);
    }
  }

  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentSurah = null;
    _currentAyah = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
