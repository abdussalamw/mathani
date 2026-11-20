import 'dart:typed_data';

import 'package:record/record.dart';

const recitationSampleRate = 16000;

abstract interface class RecitationAudioRecorder {
  Future<bool> hasPermission({bool request = false});
  Future<Stream<Uint8List>> startPcm();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> cancel();
  Future<double> getAmplitude();
  Future<void> dispose();
}

/// Captures PCM16 little-endian, mono, at the fixed rate required by Zipformer.
/// The recitation session owns the WAV file and decides when to retain it.
class AudioRecorderService implements RecitationAudioRecorder {
  AudioRecorder? _recorder;

  @override
  Future<bool> hasPermission({bool request = false}) {
    return (_recorder ??= AudioRecorder()).hasPermission(request: request);
  }

  @override
  Future<Stream<Uint8List>> startPcm() {
    return (_recorder ??= AudioRecorder()).startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: recitationSampleRate,
        numChannels: 1,
      ),
    );
  }

  @override
  Future<void> pause() async => _recorder?.pause();

  @override
  Future<void> resume() async => _recorder?.resume();

  @override
  Future<void> stop() async {
    await _recorder?.stop();
  }

  @override
  Future<void> cancel() async => _recorder?.cancel();

  @override
  Future<double> getAmplitude() async {
    final amplitude = await _recorder?.getAmplitude();
    return (((amplitude?.current ?? -60.0) + 60) / 60).clamp(0.0, 1.0);
  }

  @override
  Future<void> dispose() async {
    final recorder = _recorder;
    _recorder = null;
    await recorder?.dispose();
  }
}
