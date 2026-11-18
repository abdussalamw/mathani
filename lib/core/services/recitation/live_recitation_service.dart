// lib/core/services/recitation/live_recitation_service.dart
// ═══════════════════════════════════════════════════════════════════════════════
// خدمة إدارة جلسة التسميع اللحظي الشاملة (Live Recitation Service)
//
// تربط بين دفق الميكروفون المباشر (16kHz PCM) ومحرك Zipformer2-CTC ومطابق الكلمات.
// تعمل بالكامل محلياً (100% Offline) دون أي اتصال خارجي.
// مستلهم ومطور استناداً إلى حزمة recite_quran (v1.0.5) المرخصة لوجه الله تعالى.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'phoneme_matcher.dart';
import 'recitation_model_downloader.dart';
import 'recitation_models.dart';
import 'recitation_phoneme_repository.dart';
import 'zipformer_engine.dart';

class LiveRecitationService {
  static final LiveRecitationService _instance =
      LiveRecitationService._internal();
  factory LiveRecitationService() => _instance;
  LiveRecitationService._internal();

  final ZipformerEngine _engine = ZipformerEngine();
  final RecitationPhonemeRepository _repository = RecitationPhonemeRepository();
  AudioRecorder? _audioRecorder;
  StreamSubscription<Uint8List>? _recordSubscription;

  PhonemeWordMatcher? _matcher;
  QuranVersePhonemes? _currentVerse;
  bool _isReciting = false;

  final StreamController<List<WordMatchEvent>> _wordsStreamController =
      StreamController<List<WordMatchEvent>>.broadcast();
  final StreamController<String> _livePhonemesController =
      StreamController<String>.broadcast();

  Stream<List<WordMatchEvent>> get wordsStream => _wordsStreamController.stream;
  Stream<String> get livePhonemesStream => _livePhonemesController.stream;

  bool get isReciting => _isReciting;
  QuranVersePhonemes? get currentVerse => _currentVerse;
  List<WordMatchEvent> get currentWordStatuses =>
      _matcher?.wordStatuses ?? const [];

  /// التحقق من جاهزية المحرك والبيانات محلياً.
  Future<bool> isModelReady() async {
    return await RecitationModelDownloader.isModelReady();
  }

  /// تهيئة المحرك وقاموس الآيات.
  Future<bool> initialize() async {
    final ready = await isModelReady();
    if (!ready) return false;

    final repoLoaded = await _repository.load();
    if (!repoLoaded) return false;

    final engineInit = await _engine.initialize();
    return engineInit;
  }

  /// بدء تسميع آية محددة مع التتبع اللحظي للكلمات.
  Future<bool> startAyahRecitation({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (_isReciting) {
      await stopRecitation();
    }

    final verse = _repository.getVersePhonemes(surahNumber, ayahNumber);
    if (verse == null) {
      debugPrint('❌ لم يتم العثور على فونيمات الآية $surahNumber:$ayahNumber');
      return false;
    }

    _currentVerse = verse;
    _matcher = PhonemeWordMatcher(referenceVerse: verse);
    _wordsStreamController.add(_matcher!.wordStatuses);

    _audioRecorder ??= AudioRecorder();
    final hasPerm = await _audioRecorder!.hasPermission();
    if (!hasPerm) {
      debugPrint('❌ لا توجد صلاحية للميكروفون');
      return false;
    }

    _engine.startStream();

    try {
      // دفق صوتي خام 16kHz Mono PCM
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final audioStream = await _audioRecorder!.startStream(config);
      _isReciting = true;

      _recordSubscription = audioStream.listen(
        _onAudioChunkReceived,
        onError: (err) {
          debugPrint('❌ خطأ في دفق التسجيل: $err');
          stopRecitation();
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ فشل بدء دفق الصوت: $e');
      _isReciting = false;
      return false;
    }
  }

  /// معالجة كل حزمة صوتية قادمة من الميكروفون.
  void _onAudioChunkReceived(Uint8List bytes) {
    if (!_isReciting || _matcher == null) return;
    if (bytes.length < 2) return;

    // تحويل PCM16 إلى Float32List
    final int16List = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );

    final float32List = Float32List(int16List.length);
    for (int i = 0; i < int16List.length; i++) {
      float32List[i] = int16List[i] / 32768.0;
    }

    // تغذية المحرك
    _engine.acceptWaveform(float32List);

    // قراءة النتيجة اللحظية
    final res = _engine.getCurrentResult();
    if (res != null && res.text.isNotEmpty) {
      _livePhonemesController.add(res.text);

      // مطابقة الكلمات اللحظية وتحديث الواجهة
      final updatedWords = _matcher!.processLivePhonemes(res.text);
      _wordsStreamController.add(updatedWords);
    }
  }

  /// إيقاف جلسة التسميع.
  Future<List<WordMatchEvent>> stopRecitation() async {
    _isReciting = false;
    await _recordSubscription?.cancel();
    _recordSubscription = null;

    try {
      await _audioRecorder?.stop();
    } catch (_) {}

    _engine.finishInput();

    final finalRes = _engine.getCurrentResult();
    if (finalRes != null && _matcher != null) {
      _matcher!.processLivePhonemes(finalRes.text);
      _wordsStreamController.add(_matcher!.wordStatuses);
    }

    _engine.resetStream();
    return _matcher?.wordStatuses ?? const [];
  }

  /// تفريغ الموارد بالكامل.
  void dispose() {
    stopRecitation();
    _audioRecorder?.dispose();
    _audioRecorder = null;
    _engine.dispose();
    _repository.clearCache();
  }
}
