import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../data/services/audio_recorder_service.dart';
import 'zipformer_engine.dart';

typedef LiveRecitationResult = ({
  String phonemes,
  String? audioPath,
  int audioDurationMs,
  List<ZipformerTokenTiming> tokenTimings,
});

class LiveRecitationService {
  LiveRecitationService({
    ZipformerEngine? engine,
    RecitationAudioRecorder? recorder,
    Future<Directory> Function()? temporaryDirectory,
  }) : _engine = engine ?? const ZipformerEngine(),
       _recorder = recorder ?? AudioRecorderService(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static const _headerSize = 44;
  static const _maxPendingBytes = recitationSampleRate * 2 * 2;
  static int _fileSequence = 0;

  final ZipformerEngine _engine;
  final RecitationAudioRecorder _recorder;
  final Future<Directory> Function() _temporaryDirectory;
  Future<void> _operation = Future.value();
  _Capture? _capture;
  bool _disposed = false;

  bool get isNpuSupported => _engine.isNpuSupported;

  Future<bool> hasPermission({bool request = false}) =>
      _recorder.hasPermission(request: request);

  Future<double> getAmplitude() => _recorder.getAmplitude();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _operation.then((_) => action());
    _operation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  /// Opens a verified NPU stream before an audio file or microphone is opened.
  Future<void> prepare() {
    if (_disposed || _capture != null) {
      return Future.error(StateError('جلسة التسميع قيد الإعداد أو التشغيل.'));
    }
    final capture = _Capture();
    _capture = capture;
    return _serialize(() async {
      try {
        _ensureActive(capture);
        capture.decoder = await _engine.openStream();
        _ensureActive(capture);
      } catch (_) {
        await _release(capture);
        rethrow;
      }
    });
  }

  Future<String> start({
    required void Function(String) onPartial,
    required void Function(Object, StackTrace) onError,
    void Function()? onFirstPcm,
  }) {
    final capture = _capture;
    return _serialize(() async {
      if (capture == null ||
          capture.decoder == null ||
          !identical(_capture, capture) ||
          capture.recorderOpen) {
        throw StateError('لا توجد جلسة تسميع جاهزة للبدء.');
      }
      try {
        _ensureActive(capture);
        final directory = await _temporaryDirectory();
        _ensureActive(capture);
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final file = File(
          '${directory.path}/recitation_${timestamp}_${++_fileSequence}.wav',
        );
        await file.create(exclusive: true);
        capture.file = file;
        capture.wave = await file.open(mode: FileMode.write);
        await capture.wave!.writeFrom(Uint8List(_headerSize));
        _ensureActive(capture);

        capture.onError = onError;
        capture.recorderOpen = true;
        final stream = await _recorder.startPcm();
        _ensureActive(capture);
        capture.subscription = stream.listen(
          (chunk) => _queueChunk(capture, chunk, onPartial, onFirstPcm),
          onError: (Object error, StackTrace stack) =>
              _signalFailure(capture, error, stack),
          onDone: () {
            capture.streamDone.complete();
            if (!capture.stopping && !capture.cancelled) {
              _signalFailure(
                capture,
                StateError('انقطع بث صوت التسميع.'),
                StackTrace.current,
              );
            }
          },
        );
        return file.path;
      } catch (_) {
        await _release(capture);
        rethrow;
      }
    });
  }

  void _queueChunk(
    _Capture capture,
    Uint8List chunk,
    void Function(String) onPartial,
    void Function()? onFirstPcm,
  ) {
    if (capture.cancelled || capture.failure != null || chunk.isEmpty) return;
    if (capture.pendingBytes + chunk.length > _maxPendingBytes) {
      _signalFailure(
        capture,
        StateError('تعذّر تحليل الصوت بالسرعة اللازمة.'),
        StackTrace.current,
      );
      return;
    }
    final input = Uint8List.fromList(chunk);
    capture.pendingBytes += input.length;
    capture.pending = capture.pending
        .then((_) async {
          if (capture.cancelled || capture.failure != null) return;

          final leadingByte = capture.trailingByte;
          final bytes = leadingByte == null
              ? input
              : (Uint8List(input.length + 1)
                  ..[0] = leadingByte
                  ..setRange(1, input.length + 1, input));
          final length = bytes.length & ~1;
          capture.trailingByte = length < bytes.length ? bytes.last : null;
          if (length == 0) return;
          final data = ByteData.sublistView(bytes, 0, length);
          final samples = Float32List(length ~/ 2);
          for (var i = 0; i < samples.length; i++) {
            samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
          }

          final firstPcm = capture.writtenBytes == 0;
          await capture.wave!.writeFrom(bytes, 0, length);
          capture.writtenBytes += length;
          if (capture.cancelled || capture.failure != null) return;
          if (firstPcm && !capture.stopping) onFirstPcm?.call();

          final phonemes = await capture.decoder!.acceptPcm(samples);
          if (!capture.cancelled &&
              capture.failure == null &&
              !capture.stopping &&
              phonemes.isNotEmpty &&
              phonemes != capture.lastPhonemes) {
            capture.lastPhonemes = phonemes;
            onPartial(phonemes);
          }
        })
        .catchError((Object error, StackTrace stack) {
          _signalFailure(capture, error, stack);
        })
        .whenComplete(() {
          capture.pendingBytes -= input.length;
        });
  }

  void _signalFailure(_Capture capture, Object error, StackTrace stack) {
    if (capture.cancelled || capture.failure != null) return;
    capture.failure = (error, stack);
    // Release resources even if the observer does not request cancellation.
    _serialize(() => _release(capture)).ignore();
    capture.onError?.call(error, stack);
  }

  Future<LiveRecitationResult> finish() {
    final capture = _capture;
    return _serialize(() async {
      if (capture == null ||
          !identical(_capture, capture) ||
          capture.subscription == null) {
        throw StateError('لا توجد جلسة تسميع نشطة.');
      }
      try {
        _ensureActive(capture);
        capture.stopping = true;
        await _recorder.stop();
        capture.recorderOpen = false;
        // The record package closes its stream after the last PCM chunk.
        await capture.streamDone.future;
        await capture.pending;
        _ensureActive(capture);
        if (capture.trailingByte != null) {
          throw const FormatException('انتهى البث بعينة صوتية غير مكتملة.');
        }
        final decoder = capture.decoder!;
        final phonemes = await decoder.finish();
        _ensureActive(capture);
        var tokenTimings = const <ZipformerTokenTiming>[];
        if (decoder is ZipformerTimedNpuStream && phonemes.isNotEmpty) {
          try {
            tokenTimings = await decoder.readTokenTimings();
          } on Exception {
            // The word results can still be saved without audio clip positions.
          }
        }
        _ensureActive(capture);
        final audioDurationMs =
            capture.writtenBytes * 1000 ~/ (recitationSampleRate * 2);
        final audioPath = capture.writtenBytes == 0 ? null : capture.file!.path;
        if (audioPath != null) {
          await capture.wave!.setPosition(0);
          await capture.wave!.writeFrom(_waveHeader(capture.writtenBytes));
          await capture.wave!.flush();
        }
        _ensureActive(capture);
        await _release(capture, keepAudio: audioPath != null);
        _ensureActive(capture);
        return (
          phonemes: phonemes,
          audioPath: audioPath,
          audioDurationMs: audioDurationMs,
          tokenTimings: tokenTimings,
        );
      } catch (_) {
        await _release(capture);
        rethrow;
      }
    });
  }

  Future<void> pause() {
    final capture = _capture;
    return _serialize(() async {
      if (capture != null && capture.recorderOpen && !capture.cancelled) {
        await _recorder.pause();
      }
    });
  }

  Future<void> resume() {
    final capture = _capture;
    return _serialize(() async {
      if (capture != null && capture.recorderOpen && !capture.cancelled) {
        await _recorder.resume();
      }
    });
  }

  Future<void> cancel() {
    final capture = _capture;
    if (capture == null) return _operation;
    capture.cancelled = true;
    return _serialize(() => _release(capture));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await cancel();
    } finally {
      await _recorder.dispose();
    }
  }

  void _ensureActive(_Capture capture) {
    if (capture.cancelled) throw StateError('أُلغيت جلسة التسميع.');
    if (capture.failure case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> _release(_Capture capture, {bool keepAudio = false}) async {
    try {
      if (capture.recorderOpen) {
        capture.recorderOpen = false;
        await _recorder.cancel();
      }
    } finally {
      try {
        await capture.subscription?.cancel();
        capture.subscription = null;
        await capture.pending;
      } finally {
        try {
          final wave = capture.wave;
          capture.wave = null;
          await wave?.close();
        } finally {
          try {
            final decoder = capture.decoder;
            capture.decoder = null;
            await decoder?.close();
          } finally {
            final file = capture.file;
            try {
              if (!keepAudio && file != null) {
                capture.file = null;
                if (await file.exists()) await file.delete();
              }
            } finally {
              if (identical(_capture, capture)) _capture = null;
            }
          }
        }
      }
    }
  }

  Uint8List _waveHeader(int bytes) {
    if (bytes > 0xFFFFFFFF - 36) {
      throw const FormatException('حجم تسجيل WAV يتجاوز الحد المدعوم.');
    }
    final header = ByteData(_headerSize);
    final data = header.buffer.asUint8List();
    data.setAll(0, 'RIFF'.codeUnits);
    header.setUint32(4, bytes + 36, Endian.little);
    data.setAll(8, 'WAVEfmt '.codeUnits);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, recitationSampleRate, Endian.little);
    header.setUint32(28, recitationSampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    data.setAll(36, 'data'.codeUnits);
    header.setUint32(40, bytes, Endian.little);
    return data;
  }
}

class _Capture {
  final streamDone = Completer<void>();
  Future<void> pending = Future.value();
  int pendingBytes = 0;
  int writtenBytes = 0;
  int? trailingByte;
  String lastPhonemes = '';
  bool cancelled = false;
  bool stopping = false;
  bool recorderOpen = false;
  (Object, StackTrace)? failure;
  ZipformerNpuStream? decoder;
  StreamSubscription<Uint8List>? subscription;
  File? file;
  RandomAccessFile? wave;
  void Function(Object, StackTrace)? onError;
}
