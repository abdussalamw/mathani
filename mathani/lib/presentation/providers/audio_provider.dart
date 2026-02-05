import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/services/audio_service.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../core/di/service_locator.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService = AudioService();
  final QuranRepository _quranRepository;
  
  bool _isPlaying = false;
  int? _currentSurah;
  int? _currentAyah;
  int? _currentSurahTotalAyahs;

  // Reciter IDs must match https://everyayah.com/data/
  final List<Map<String, String>> reciters = [
    {'id': 'Minshawi_Murattal_128kbps', 'name': 'محمد صديق المنشاوي (مرتل)'},
    {'id': 'Abdul_Basit_Murattal_192kbps', 'name': 'عبد الباسط عبد الصمد (مرتل)'},
    {'id': 'Alafasy_128kbps', 'name': 'مشاري راشد العفاسي'},
    {'id': 'Husary_128kbps', 'name': 'محمود خليل الحصري'},
    {'id': 'Hudhaify_128kbps', 'name': 'علي الحذيفي'},
  ];

  late Map<String, String> _currentReciter;

  bool get isPlaying => _isPlaying;
  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  Map<String, String> get currentReciter => _currentReciter;

  AudioProvider({QuranRepository? quranRepository}) 
      : _quranRepository = quranRepository ?? sl<QuranRepository>() {
    _currentReciter = reciters[0];
    _initPlayer();
  }
  
  void _initPlayer() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        // Auto-advance logic
        if (_currentSurah != null && _currentAyah != null && _currentSurahTotalAyahs != null) {
          if (_currentAyah! < _currentSurahTotalAyahs!) {
             // Next Ayah in same Surah
             playAyah(_currentSurah!, _currentAyah! + 1, totalAyahsInSurah: _currentSurahTotalAyahs);
             return;
          } else if (_currentSurah! < 114) {
             // Next Surah, Ayah 1
             playAyah(_currentSurah! + 1, 1); 
             return;
          }
        }
        _isPlaying = false;
        _currentSurah = null;
        _currentAyah = null;
      }
      notifyListeners();
    });
  }

  /// Play a specific Ayah. 
  /// [shouldCache]: If true, will download the file locally for future use.
  Future<void> playAyah(int surah, int ayah, {bool shouldCache = true, int? totalAyahsInSurah}) async {
    try {
      _currentSurah = surah;
      _currentAyah = ayah;
      
      // If totalAyahsInSurah is not provided, we should try to get it for auto-advance
      if (totalAyahsInSurah != null) {
        _currentSurahTotalAyahs = totalAyahsInSurah;
      } else {
        // Fetch from repository
        final result = await _quranRepository.getSurahByNumber(surah);
        result.fold(
          (l) => debugPrint('Metadata error: ${l.message}'),
          (s) => _currentSurahTotalAyahs = s?.numberOfAyahs,
        );
      }
      
      notifyListeners(); 

      final reciterId = _currentReciter['id']!;
      
      // 1. Check Local File
      if (await _audioService.isAyahDownloaded(reciterId, surah, ayah)) {
        final path = await _audioService.getAyahPath(reciterId, surah, ayah);
        await _player.setFilePath(path);
      } else {
        // 2. Stream Remote
        final url = _audioService.getRemoteUrl(reciterId, surah, ayah);
        await _player.setUrl(url); // Start streaming immediately
        
        // 3. Cache in background if enabled
        if (shouldCache) {
          _audioService.downloadAyah(reciterId, surah, ayah).then((path) {
             if (path != null) {
               debugPrint('Cached: $path');
             }
          });
        }
      }
      
      await _player.play();
    } catch (e) {
      debugPrint('Audio Play Error: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  void setReciter(Map<String, String> reciter) {
    _currentReciter = reciter;
    notifyListeners();
    // If playing, we could restart with new reciter, but simpler to just set state for next play
    if (_isPlaying && _currentSurah != null && _currentAyah != null) {
       // Optional: Restart playback with new reciter? 
       // For now, let's stop to avoid confusion or mixed audio states
       stop();
    }
  }

  Future<void> play() async {
    if (_player.audioSource != null) {
        await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
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
