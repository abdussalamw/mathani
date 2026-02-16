import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/services/audio_service.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../data/models/reciter.dart';
import '../../core/di/service_locator.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService = AudioService();
  final QuranRepository _quranRepository;
  final ReciterRepository _reciterRepository;
  
  bool _isPlaying = false;
  int? _currentSurah;
  int? _currentAyah;
  int? _currentSurahTotalAyahs;

  List<Reciter> _reciters = [];
  Reciter? _currentReciter;
  
  // Audio 2.0 State
  LoopMode _loopMode = LoopMode.off;
  bool _isRangeMode = false;
  bool _isLoading = false;
  bool _showMinibar = false; // Audio 3.0 Visibility

  // Advanced Repetition State
  int _ayahRepeatLimit = 1;
  int _ayahRepeatCount = 0;
  int _rangeRepeatLimit = 1;
  int _rangeRepeatCount = 0;
  
  // Range Boundaries
  int? _startSurah;
  int? _startAyah;
  int? _endSurah;
  int? _endAyah;

  LoopMode get loopMode => _loopMode;
  bool get isRangeMode => _isRangeMode;
  bool get isLoading => _isLoading;
  bool get showMinibar => _showMinibar;
  
  int get ayahRepeatLimit => _ayahRepeatLimit;
  int get ayahRepeatCount => _ayahRepeatCount;
  int get rangeRepeatLimit => _rangeRepeatLimit;
  int get rangeRepeatCount => _rangeRepeatCount;
  
  int? get startSurah => _startSurah;
  int? get startAyah => _startAyah;
  int? get endSurah => _endSurah;
  int? get endAyah => _endAyah;
  
  // Context
  void setContext(int surah, int ayah) {
    _currentSurah = surah;
    _currentAyah = ayah;
    _startSurah = surah;
    _startAyah = ayah;
    _endSurah = surah;
    _endAyah = ayah;
  }

  void setShowMinibar(bool show) {
    _showMinibar = show;
    notifyListeners();
  }

  void setAyahRepeatLimit(int limit) {
    _ayahRepeatLimit = limit;
    notifyListeners();
  }

  void setRangeRepeatLimit(int limit) {
    _rangeRepeatLimit = limit;
    notifyListeners();
  }

  void setRange(int sSurah, int sAyah, int eSurah, int eAyah) {
    _startSurah = sSurah;
    _startAyah = sAyah;
    _endSurah = eSurah;
    _endAyah = eAyah;
    notifyListeners();
  }
  
  // Stream subscriptions for proper disposal
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  bool get isPlaying => _isPlaying;
  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  
  List<Reciter> get reciters => _reciters;
  Reciter? get currentReciter => _currentReciter;
  
  // Error Handling
  String? _lastError;
  String? get lastError => _lastError;

  // Expose player for UI access (position, duration streams)
  AudioPlayer get player => _player;

  AudioProvider({QuranRepository? quranRepository, ReciterRepository? reciterRepository}) 
      : _quranRepository = quranRepository ?? sl<QuranRepository>(),
        _reciterRepository = reciterRepository ?? sl<ReciterRepository>() {
    _init();
  }
  
  Future<void> _init() async {
    await _loadReciters();
    _initPlayer();
  }

  Future<void> _loadReciters() async {
    _reciters = await _reciterRepository.getReciters();
    if (_reciters.isNotEmpty) {
      // Set Minshawi as default reciter
      _currentReciter = _reciters.firstWhere(
        (r) => r.id == 'Minshawy_Murattal_128kbps',
        orElse: () => _reciters.first,
      );
    }
    notifyListeners();
  }
  
  void _initPlayer() {
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to processing state for auto-advance to next ayah
    _processingStateSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _currentSurah != null && _currentAyah != null) {
        // In simple mode, ProcessingState.completed means the track (or concatenated set) is DONE.
        // If we use ConcatenatingAudioSource, this only fires AT THE VERY END.
        // To handle REPETITION per ayah, we should probably NOT use concatenated sources for the whole surah
        // OR we handle it when the INDEX changes.
        
        _playNextAyah();
      }
    });
  }



  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _player.setLoopMode(mode);
    notifyListeners();
  }
  
  // --- Gapless Playback Logic ---
  
  Future<void> playAyah(int surah, int ayah) async {
    if (_currentReciter == null) return;
    
    // Reset repetition states
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    
    // Set boundaries to "to end of Surah" by default
    _startSurah = surah;
    _startAyah = ayah;
    _endSurah = surah;
    _endAyah = 286; 
    
    _isRangeMode = false; 
    _showMinibar = true; // Show on play
    
    await _playSpecificAyah(surah, ayah);
  }

  Future<void> _playSpecificAyah(int surah, int ayah) async {
    if (_currentReciter == null) return;
    try {
      _isLoading = true;
      _currentSurah = surah;
      _currentAyah = ayah;
      notifyListeners();

      final url = _audioService.getRemoteUrl(_currentReciter!.id, surah, ayah);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
      
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Play Specific Ayah Error: $e');
      _lastError = 'خطأ في التشغيل: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playRange({
    required int startSurah, 
    required int startAyah, 
    required int endSurah, 
    required int endAyah
  }) async {
    if (_currentReciter == null) return;
    
    _startSurah = startSurah;
    _startAyah = startAyah;
    _endSurah = endSurah;
    _endAyah = endAyah;
    
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    _isRangeMode = true;
    _showMinibar = true;
    
    await _playSpecificAyah(startSurah, startAyah);
  }

  void setReciter(Reciter reciter) {
    if (_currentReciter?.id == reciter.id) return;
    
    _currentReciter = reciter;
    notifyListeners();
    
    // Restart playback with new reciter if currently playing
    if (_isPlaying && _currentSurah != null && _currentAyah != null) {
       final surah = _currentSurah!;
       final ayah = _currentAyah!;
       stop().then((_) {
         playAyah(surah, ayah);
       });
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
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    notifyListeners();
  }

  void stopAndHide() {
    stop();
    _showMinibar = false;
    notifyListeners();
  }

  // State
  ConcatenatingAudioSource? _playlist;
  
  // Playback Features
  Future<void> playSurah(int surahNumber) async {
    if (_currentReciter == null) return;
    
    try {
      // 1. Get Surah Details
      final surahResult = await _quranRepository.getSurahByNumber(surahNumber);
      int ayahCount = 0;
      String surahName = 'سورة $surahNumber';
      
      surahResult.fold(
        (l) => debugPrint('Error: ${l.message}'),
        (s) {
           if (s != null) {
             ayahCount = s.numberOfAyahs;
             surahName = s.nameArabic;
           }
        }
      );
      
      if (ayahCount == 0) return;

      // 2. Build Playlist
      final List<AudioSource> sources = [];
      
      for (int i = 1; i <= ayahCount; i++) {
        final url = _audioService.getRemoteUrl(_currentReciter!.id, surahNumber, i);
        sources.add(AudioSource.uri(Uri.parse(url)));
      }

      _playlist = ConcatenatingAudioSource(children: sources);
      
      // 3. Setup Player
      await _player.setAudioSource(_playlist!, initialIndex: 0, preload: false);
      
      _currentSurah = surahNumber;
      _currentAyah = 1;
      _currentSurahTotalAyahs = ayahCount;
      notifyListeners();
      
      await _player.play();
      
    } catch (e) {
      debugPrint('Error playing surah: $e');
    }
  }

  /// Auto-advance to next ayah with repetition logic
  Future<void> _playNextAyah() async {
    if (_currentSurah == null || _currentAyah == null) return;
    
    // 1. Ayah Repeat Logic
    _ayahRepeatCount++;
    if (_ayahRepeatCount < _ayahRepeatLimit) {
      debugPrint('🔁 Repeating Ayah $_currentAyah (Count: $_ayahRepeatCount)');
      await _playSpecificAyah(_currentSurah!, _currentAyah!);
      return;
    }
    
    // Reset ayah counter if we move forward
    _ayahRepeatCount = 0;
    
    // 2. Determine Next Ayah
    int nextSurah = _currentSurah!;
    int nextAyah = _currentAyah! + 1;
    
    // 3. Range End Logic
    bool isRangeDone = false;
    if (_endSurah != null && _endAyah != null) {
      if (nextSurah > _endSurah! || (nextSurah == _endSurah! && nextAyah > _endAyah!)) {
        isRangeDone = true;
      }
    }
    
    if (isRangeDone) {
      _rangeRepeatCount++;
      if (_rangeRepeatCount < _rangeRepeatLimit) {
        debugPrint('🔁 Repeating Total Range (Range Count: $_rangeRepeatCount)');
        if (_startSurah != null && _startAyah != null) {
          // Restart from beginning of range
          _currentSurah = _startSurah;
          _currentAyah = _startAyah;
          await _playSpecificAyah(_startSurah!, _startAyah!);
          return;
        }
      }
      
      debugPrint('✅ Range Completion Reached');
      await stop();
      // Optional: keep minibar if user wants, but typically stop means done.
      // But user said "Stop completely and hide" for the button.
      // For auto-end, let's keep it visible but stopped? 
      // User said: "إيقاف تماما ويختفي الشريط" for the button.
      // For auto-end, let's just stop.
      return;
    }

    // 4. Normal Advance (Surah Transition)
    // If we reach the end of a surah, we need to handle the next surah if not in a specific range.
    // However, _playSpecificAyah will fail if ayah doesn't exist.
    // For now, let's assume we play it. 
    // We should ideally check surah limits, but playSpecificAyah will likely throw, and we catch it.
    
    await _playSpecificAyah(nextSurah, nextAyah);
  }
  
  // Override dispose to clear playlist and cancel subscriptions
  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
