import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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

  ConcatenatingAudioSource? _playlist;

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
  
  // Context - يُحدَّث فقط إذا لم يكن هناك صوت يعمل أو متوقف مؤقتاً
  void setContext(int surah, int ayah) {
    // ★ لا تكتب فوق سياق تشغيل نشط أو متوقف مؤقتاً (pause)
    if (_isPlaying) return;
    if (_player.processingState == ProcessingState.ready) return; // paused
    
    _currentSurah = surah;
    _currentAyah = ayah;
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
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to current sequence index to update UI track info
    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && _playlist != null && index < _playlist!.length) {
         try {
           final child = _playlist!.children[index] as UriAudioSource;
           final tag = child.tag as MediaItem;
           final parts = tag.id.split('_'); // Format: surah_ayah_index
           if (parts.length >= 2) {
             final newSurah = int.tryParse(parts[0]);
             final newAyah = int.tryParse(parts[1]);
             if (newSurah != null && newAyah != null && (_currentSurah != newSurah || _currentAyah != newAyah)) {
                _currentSurah = newSurah;
                _currentAyah = newAyah;
                notifyListeners();
             }
           }
         } catch (e) {
           debugPrint('Error parsing current index tag: $e');
         }
      }
    });

    // To auto-hide when playlist completely finishes
    _processingStateSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
         _isPlaying = false;
         _playlist = null; // ★ تنظيف الـ playlist عند الانتهاء
         notifyListeners();
      }
    });
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _player.setLoopMode(mode);
    notifyListeners();
  }
  
  // --- True Gapless & Background Playback Logic ---

  Future<void> playAyah(int surah, int ayah) async {
    // جلب عدد آيات السورة الفعلي بدل الرقم الثابت
    int endAyah = 999; // سيتم تقليصه في _buildAndPlayPlaylist
    final surahResult = await _quranRepository.getSurahByNumber(surah);
    surahResult.fold((l) {}, (s) {
      if (s != null) endAyah = s.numberOfAyahs;
    });
    await playRange(startSurah: surah, startAyah: ayah, endSurah: surah, endAyah: endAyah);
  }

  Future<void> playRange({
    required int startSurah, 
    required int startAyah, 
    required int endSurah, 
    required int endAyah
  }) async {
    if (_currentReciter == null) return;
    if (_isLoading) return; // ★ منع الضغط المزدوج
    
    _startSurah = startSurah;
    _startAyah = startAyah;
    _endSurah = endSurah;
    _endAyah = endAyah;
    
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    _isRangeMode = true;
    _showMinibar = true;
    _isLoading = true;
    notifyListeners();

    try {
      await _buildAndPlayPlaylist(startSurah, startAyah, endSurah, endAyah);
    } catch (e) {
      debugPrint('PlayRange Error: $e');
      _lastError = 'خطأ في التشغيل: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _buildAndPlayPlaylist(int sSurah, int sAyah, int eSurah, int eAyah) async {
    final List<AudioSource> sources = [];
    int trackIndex = 0;

    // Outer loop for range repeats
    for (int rangeRep = 0; rangeRep < _rangeRepeatLimit; rangeRep++) {
      
      int currentSurah = sSurah;
      while (currentSurah <= eSurah) {
        // Get Surah length
        final surahResult = await _quranRepository.getSurahByNumber(currentSurah);
        int maxAyahs = 0;
        String surahName = 'سورة $currentSurah';
        surahResult.fold((l) {}, (s) {
           if (s != null) {
             maxAyahs = s.numberOfAyahs;
             surahName = s.nameArabic;
           }
        });
        
        if (maxAyahs == 0) {
          currentSurah++;
          continue; // ★ تخطي السورة إذا لم نجد بياناتها
        }
        
        int startA = (currentSurah == sSurah) ? sAyah : 1;
        int endA = (currentSurah == eSurah) ? eAyah.clamp(1, maxAyahs) : maxAyahs;

        for (int a = startA; a <= endA; a++) {
          
          // Inner loop for Ayah repeats
          for (int ayahRep = 0; ayahRep < _ayahRepeatLimit; ayahRep++) {
             final url = _audioService.getRemoteUrl(_currentReciter!.id, currentSurah, a);
             
             // Background Audio Metadata
             final tag = MediaItem(
                id: '${currentSurah}_${a}_$trackIndex', // Unique ID
                album: _currentReciter!.name,
                title: 'سورة $surahName - آية $a',
                artist: _currentReciter!.name,
                // Add artwork if needed
             );
             
             sources.add(AudioSource.uri(Uri.parse(url), tag: tag));
             trackIndex++;
          }
        }
        currentSurah++;
      }
    }

    if (sources.isEmpty) return;

    _playlist = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(_playlist!, initialIndex: 0, preload: false);
    
    _currentSurah = sSurah;
    _currentAyah = sAyah;
    
    await _player.play();
  }

  Future<void> playSurah(int surahNumber) async {
    int endAyah = 999;
    final surahResult = await _quranRepository.getSurahByNumber(surahNumber);
    surahResult.fold((l) {}, (s) {
      if (s != null) endAyah = s.numberOfAyahs;
    });
    await playRange(startSurah: surahNumber, startAyah: 1, endSurah: surahNumber, endAyah: endAyah);
  }
  
  // --- Control Methods ---

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

  /// ★ استئناف من الإيقاف المؤقت، أو تشغيل جديد من السياق
  Future<void> resumeOrPlay() async {
    // الحالة 1: متوقف مؤقتاً (paused) → استأنف
    if (_player.processingState == ProcessingState.ready && !_player.playing) {
      await _player.play();
      return;
    }
    // الحالة 2: لا يوجد مصدر صوت (بعد stop) → شغّل من السياق
    if (_currentSurah != null && _currentAyah != null) {
      await playAyah(_currentSurah!, _currentAyah!);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  /// ★ إيقاف كامل: يمسح كل شيء ويسمح بالتنقل لسورة أخرى
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentSurah = null;
    _currentAyah = null;
    _playlist = null;
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    notifyListeners();
  }

  /// ★ إيقاف نهائي وإخفاء كل الواجهة
  Future<void> stopAndHide() async {
    await _player.stop();
    _isPlaying = false;
    _currentSurah = null;
    _currentAyah = null;
    _playlist = null;
    _showMinibar = false;
    _ayahRepeatCount = 0;
    _rangeRepeatCount = 0;
    _startSurah = null;
    _startAyah = null;
    _endSurah = null;
    _endAyah = null;
    notifyListeners();
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
