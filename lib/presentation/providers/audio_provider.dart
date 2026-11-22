import 'dart:math' as math;
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/services/audio_service.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../data/models/reciter.dart';
import '../../core/di/service_locator.dart';

typedef _Verse = ({int surah, int ayah, String name});

class _AudioRange {
  _AudioRange(this.verses, this.reciter, this.ayahRepeats, this.rangeRepeats);
  final List<_Verse> verses;
  final Reciter reciter;
  final int ayahRepeats;
  final int rangeRepeats;
  int get length => verses.length * ayahRepeats * rangeRepeats;
  _Verse verseAt(int index) => verses[(index ~/ ayahRepeats) % verses.length];
}

class AudioProvider extends ChangeNotifier {
  bool _disposed = false;
  int _operation = 0;
  final AudioPlayer _player;
  final AudioService _audioService = AudioService();
  final QuranRepository _quranRepository;
  final ReciterRepository _reciterRepository;

  bool _isPlaying = false;
  int? _currentSurah;
  int? _currentAyah;

  List<AudioSource>? _playlist;
  static const _windowSize = 600;
  _AudioRange? _range;
  int _windowStart = 0;

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
    if (_ayahRepeatLimit == limit.clamp(1, 20)) return;
    _ayahRepeatLimit = limit.clamp(1, 20);
    _applyRepeats();
  }

  void setRangeRepeatLimit(int limit) {
    if (_rangeRepeatLimit == limit.clamp(1, 20)) return;
    _rangeRepeatLimit = limit.clamp(1, 20);
    _applyRepeats();
  }

  void _applyRepeats() {
    notifyListeners();
    if (_range != null && !_isLoading) {
      unawaited(
        playRange(
          startSurah: _startSurah!,
          startAyah: _startAyah!,
          endSurah: _endSurah!,
          endAyah: _endAyah!,
          preserveCurrentPosition: true,
        ),
      );
    }
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

  List<({int index, MediaItem item})> get upcomingTracks {
    final playlist = _playlist;
    if (playlist == null) return [];
    final start = (_player.currentIndex ?? -1) + 1;
    return [
      for (var i = start; i < playlist.length && i < start + 5; i++)
        (index: i, item: (playlist[i] as UriAudioSource).tag as MediaItem),
    ];
  }

  Future<void> skipToTrack(int index) async {
    if (_playlist == null || index < 0 || index >= _playlist!.length) return;
    try {
      await _player.seek(Duration.zero, index: index);
    } catch (e) {
      if (_disposed) return;
      _lastError = 'تعذّر الانتقال إلى الآية، يرجى إعادة المحاولة';
      notifyListeners();
    }
  }

  AudioProvider({
    QuranRepository? quranRepository,
    ReciterRepository? reciterRepository,
    AudioPlayer? player,
  }) : _player = player ?? AudioPlayer(),
       _quranRepository = quranRepository ?? sl<QuranRepository>(),
       _reciterRepository = reciterRepository ?? sl<ReciterRepository>() {
    _init();
  }

  Future<void> _init() async {
    await _loadReciters();
    if (_disposed) return;
    _initPlayer();
  }

  Future<void> _loadReciters() async {
    _reciters = await _reciterRepository.getReciters();
    if (_disposed) return;
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
      final range = _range;
      if (index == null ||
          index < 0 ||
          range == null ||
          index >= (_playlist?.length ?? 0)) {
        return;
      }
      _updateTrack(range, _windowStart + index);
      notifyListeners();
    });

    // To auto-hide when playlist completely finishes or handle range loops
    _processingStateSubscription = _player.processingStateStream.listen((
      state,
    ) {
      if (state != ProcessingState.completed || _isLoading || _range == null) {
        return;
      }
      final next = _windowStart + (_playlist?.length ?? 0);
      if (next < _range!.length || _loopMode == LoopMode.all) {
        unawaited(_switchWindow(next < _range!.length ? next : 0, play: true));
      } else {
        _isPlaying = false;
        _playlist = null;
        _range = null;
        notifyListeners();
      }
    });
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    // Loop the logical range across windows, including its final partial window.
    await _player.setLoopMode(mode == LoopMode.all ? LoopMode.off : mode);
    notifyListeners();
  }

  // --- True Gapless & Background Playback Logic ---

  Future<void> playAyah(int surah, int ayah) async {
    if (_disposed || _isLoading) return;
    final operation = ++_operation;
    final result = await _quranRepository.getSurahByNumber(surah);
    if (_disposed || operation != _operation) return;
    final endAyah = result.fold((_) => null, (value) => value?.numberOfAyahs);
    if (endAyah == null || endAyah < ayah) {
      _lastError = 'تعذّر تحديد نطاق الآيات المطلوب';
      notifyListeners();
      return;
    }
    await playRange(
      startSurah: surah,
      startAyah: ayah,
      endSurah: surah,
      endAyah: endAyah,
    );
  }

  Future<void> playRange({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
    bool preserveCurrentPosition = false,
  }) async {
    if (_disposed || _currentReciter == null) return;
    if (_isLoading) return; // ★ منع الضغط المزدوج
    if (startSurah < 1 ||
        endSurah > 114 ||
        startSurah > endSurah ||
        startAyah < 1 ||
        endAyah < 1 ||
        (startSurah == endSurah && startAyah > endAyah)) {
      _lastError = 'يرجى اختيار نطاق آيات صحيح';
      notifyListeners();
      return;
    }
    final operation = ++_operation;
    _lastError = null;

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
      await _buildAndPlayPlaylist(
        startSurah,
        startAyah,
        endSurah,
        endAyah,
        operation: operation,
        preserveCurrentPosition: preserveCurrentPosition,
      );
    } catch (e) {
      if (_disposed || operation != _operation) return;
      debugPrint('PlayRange Error: $e');
      _lastError = 'لا يمكن التشغيل، يرجى التحقق من اتصالك بالإنترنت';
    } finally {
      if (!_disposed && operation == _operation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _buildAndPlayPlaylist(
    int sSurah,
    int sAyah,
    int eSurah,
    int eAyah, {
    required int operation,
    required bool preserveCurrentPosition,
  }) async {
    final reciter = _currentReciter!;
    final oldSurah = _currentSurah;
    final oldAyah = _currentAyah;
    final oldPosition = preserveCurrentPosition
        ? _player.position
        : Duration.zero;
    final shouldPlay = !preserveCurrentPosition || _player.playing;
    final verses = <_Verse>[];

    // Single-pass range construction (Range repeats are handled via playback completion loop)
    int currentSurah = sSurah;
    while (currentSurah <= eSurah) {
      // Get Surah length
      final surahResult = await _quranRepository.getSurahByNumber(currentSurah);
      if (_disposed || operation != _operation) return;
      int maxAyahs = 0;
      String surahName = 'سورة $currentSurah';
      surahResult.fold((l) {}, (s) {
        if (s != null) {
          maxAyahs = s.numberOfAyahs;
          surahName = s.nameArabic;
        }
      });

      if (maxAyahs == 0) {
        throw StateError('تعذّر تحديد عدد آيات السورة $currentSurah');
      }

      int startA = (currentSurah == sSurah) ? sAyah : 1;
      int endA = (currentSurah == eSurah) ? eAyah.clamp(1, maxAyahs) : maxAyahs;

      for (int a = startA; a <= endA; a++) {
        verses.add((surah: currentSurah, ayah: a, name: surahName));
      }
      currentSurah++;
    }

    if (verses.isEmpty) throw StateError('No verses in the selected range');
    final range = _AudioRange(
      verses,
      reciter,
      _ayahRepeatLimit,
      _rangeRepeatLimit,
    );
    final retained = preserveCurrentPosition
        ? verses.indexWhere((v) => v.surah == oldSurah && v.ayah == oldAyah)
        : -1;
    _range = range;
    await _installWindow(
      range,
      math.max(retained, 0) * range.ayahRepeats,
      operation,
      play: shouldPlay,
      position: retained < 0 ? Duration.zero : oldPosition,
    );
  }

  Future<void> _installWindow(
    _AudioRange range,
    int index,
    int operation, {
    required bool play,
    Duration position = Duration.zero,
  }) async {
    final start = index ~/ _windowSize * _windowSize;
    final sources = <AudioSource>[];
    for (var i = start; i < math.min(start + _windowSize, range.length); i++) {
      final verse = range.verseAt(i);
      final url = _audioService.getRemoteUrl(
        range.reciter.id,
        verse.surah,
        verse.ayah,
      );
      sources.add(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '${verse.surah}_${verse.ayah}_$i',
            album: range.reciter.name,
            title: 'سورة ${verse.name} - آية ${verse.ayah}',
            artist: range.reciter.name,
          ),
        ),
      );
    }
    _windowStart = start;
    _playlist = sources;
    await _player.setAudioSources(
      sources,
      initialIndex: index - start,
      initialPosition: position,
      preload: false,
    );
    if (_disposed || operation != _operation) return;
    _updateTrack(range, index);
    if (play) unawaited(_startPlayback(operation));
  }

  void _updateTrack(_AudioRange range, int index) {
    final verse = range.verseAt(index);
    _currentSurah = verse.surah;
    _currentAyah = verse.ayah;
    _ayahRepeatCount = index % range.ayahRepeats;
    _rangeRepeatCount = index ~/ (range.verses.length * range.ayahRepeats);
  }

  Future<void> _switchWindow(int index, {required bool play}) async {
    final range = _range;
    if (_disposed || _isLoading || range == null) return;
    final operation = ++_operation;
    _isLoading = true;
    try {
      await _installWindow(range, index, operation, play: play);
    } catch (_) {
      if (!_disposed && operation == _operation) {
        _lastError = 'تعذّر تحميل المقطع التالي';
      }
    } finally {
      if (!_disposed && operation == _operation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> skipRelative(int delta) async {
    final range = _range;
    if (_isLoading) return;
    if (range != null) {
      final index = _windowStart + (_player.currentIndex ?? 0) + delta;
      if (index >= 0 && index < range.length) {
        final offset = index - _windowStart;
        if (offset >= 0 && offset < (_playlist?.length ?? 0)) {
          await skipToTrack(offset);
        } else {
          await _switchWindow(index, play: _player.playing);
        }
      }
      return;
    }
    if (_currentSurah != null &&
        _currentAyah != null &&
        _currentAyah! + delta >= 1) {
      await playAyah(_currentSurah!, _currentAyah! + delta);
    }
  }

  Future<void> _startPlayback(int operation) async {
    try {
      await _player.play();
    } catch (e) {
      if (_disposed || operation != _operation) return;
      _lastError =
          'تعذّر تشغيل التلاوة، يرجى التحقق من الاتصال وإعادة المحاولة';
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> playSurah(int surahNumber) => playAyah(surahNumber, 1);

  // --- Control Methods ---

  void setReciter(Reciter reciter) {
    if (_currentReciter?.id == reciter.id) return;

    _currentReciter = reciter;
    notifyListeners();

    // Reload playback with new reciter while preserving range, active ayah and position
    if (_currentSurah != null &&
        _currentAyah != null &&
        (_isPlaying || _player.processingState == ProcessingState.ready)) {
      final sSurah = _startSurah ?? _currentSurah!;
      final sAyah = _startAyah ?? _currentAyah!;
      final eSurah = _endSurah ?? _currentSurah!;
      final eAyah = _endAyah ?? _currentAyah!;
      playRange(
        startSurah: sSurah,
        startAyah: sAyah,
        endSurah: eSurah,
        endAyah: eAyah,
        preserveCurrentPosition: true,
      );
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
    final operation = ++_operation;
    _isLoading = false;
    _range = null;
    await _player.stop();
    if (_disposed || operation != _operation) return;
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
    final operation = ++_operation;
    _isLoading = false;
    _range = null;
    await _player.stop();
    if (_disposed || operation != _operation) return;
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
    _disposed = true;
    _operation++;
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
