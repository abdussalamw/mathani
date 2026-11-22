import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/live_recitation_service.dart';
import 'package:mathani/core/services/recitation/zipformer_engine.dart';
import 'package:mathani/data/services/audio_recorder_service.dart';

class _Recorder implements RecitationAudioRecorder {
  StreamController<Uint8List>? _audio;
  int starts = 0;
  int stops = 0;
  int cancels = 0;

  @override
  Future<Stream<Uint8List>> startPcm() async {
    starts++;
    final audio = StreamController<Uint8List>.broadcast();
    _audio = audio;
    return audio.stream;
  }

  void emit(List<int> bytes) => _audio!.add(Uint8List.fromList(bytes));

  @override
  Future<void> stop() async {
    stops++;
    await _audio?.close();
  }

  @override
  Future<void> cancel() async {
    cancels++;
    await _audio?.close();
  }

  @override
  Future<bool> hasPermission({bool request = false}) async => true;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<double> getAmplitude() async => 0;

  @override
  Future<void> dispose() async {}
}

class _Decoder implements ZipformerNpuStream {
  _Decoder({this.onSamples});

  final Future<void> Function()? onSamples;
  final samples = <double>[];
  int finishes = 0;
  int closes = 0;

  @override
  Future<String> acceptPcm(Float32List chunk) async {
    samples.addAll(chunk);
    await onSamples?.call();
    return 'partial_${samples.length}';
  }

  @override
  Future<String> finish() async {
    finishes++;
    return 'final';
  }

  @override
  Future<void> close() async {
    closes++;
  }
}

void main() {
  late Directory directory;
  late _Recorder recorder;
  late LiveRecitationService service;

  void failIfNotExpected(Object error, StackTrace stack) =>
      fail('Unexpected capture error: $error');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'mathani_recitation_test_',
    );
    recorder = _Recorder();
  });

  tearDown(() async {
    await service.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'rejects recording before opening the microphone without verified NPU',
    () async {
      service = LiveRecitationService(
        recorder: recorder,
        temporaryDirectory: () async => directory,
      );
      expect(service.isNpuSupported, isFalse);
      await expectLater(
        service.prepare(),
        throwsA(isA<ZipformerNpuUnavailable>()),
      );
      expect(recorder.starts, 0);
      expect(directory.listSync(), isEmpty);
    },
  );

  test(
    'a preparation cancelled while opening releases the resulting stream',
    () async {
      final opening = Completer<void>();
      final pending = Completer<ZipformerNpuStream>();
      final decoder = _Decoder();
      service = LiveRecitationService(
        engine: ZipformerEngine(
          openVerifiedNpuStream: () {
            opening.complete();
            return pending.future;
          },
        ),
        recorder: recorder,
        temporaryDirectory: () async => directory,
      );

      final preparing = expectLater(service.prepare(), throwsStateError);
      await opening.future;
      final cancelling = service.cancel();
      pending.complete(decoder);
      await Future.wait([cancelling, preparing]);

      expect(recorder.starts, 0);
      expect(decoder.closes, 1);
    },
  );

  test(
    'passes PCM samples once across chunk boundaries and saves the same bytes',
    () async {
      final decoders = <_Decoder>[];
      service = LiveRecitationService(
        engine: ZipformerEngine(
          openVerifiedNpuStream: () async {
            final decoder = _Decoder();
            decoders.add(decoder);
            return decoder;
          },
        ),
        recorder: recorder,
        temporaryDirectory: () async => directory,
      );

      await service.prepare();
      final saved = await service.start(
        onPartial: (_) {},
        onError: failIfNotExpected,
      );
      recorder.emit([0]);
      recorder.emit([128, 255, 127, 0]);
      recorder.emit([0, 0, 64]);
      final result = await service.finish();

      expect(result.phonemes, 'final');
      expect(result.audioPath, saved);
      expect(decoders.single.samples, [-1, 32767 / 32768, 0, 0.5]);
      expect(decoders.single.finishes, 1);
      expect(decoders.single.closes, 1);
      expect(recorder.starts, 1);
      expect(recorder.stops, 1);

      final bytes = await File(saved).readAsBytes();
      final header = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(header.getUint32(4, Endian.little), 44);
      expect(header.getUint32(24, Endian.little), 16000);
      expect(header.getUint32(40, Endian.little), 8);
      expect(bytes.skip(44), [0, 128, 255, 127, 0, 0, 0, 64]);

      await service.prepare();
      final discarded = await service.start(
        onPartial: (_) {},
        onError: failIfNotExpected,
      );
      await service.cancel();
      expect(await File(discarded).exists(), isFalse);
      expect(await File(saved).exists(), isTrue);
      expect(recorder.cancels, 1);
      expect(decoders.last.finishes, 0);
      expect(decoders.last.closes, 1);
    },
  );

  test('rejects an incomplete final sample and removes the WAV file', () async {
    final decoder = _Decoder();
    service = LiveRecitationService(
      engine: ZipformerEngine(openVerifiedNpuStream: () async => decoder),
      recorder: recorder,
      temporaryDirectory: () async => directory,
    );

    await service.prepare();
    final path = await service.start(
      onPartial: (_) {},
      onError: failIfNotExpected,
    );
    recorder.emit([1, 2, 3]);
    await expectLater(service.finish(), throwsFormatException);
    expect(await File(path).exists(), isFalse);
    expect(decoder.finishes, 0);
    expect(decoder.closes, 1);
  });

  test(
    'aborts bounded capture when a delayed decoder cannot keep up',
    () async {
      final inDecoder = Completer<void>();
      final completeDecode = Completer<void>();
      final stopped = Completer<Object>();
      final decoder = _Decoder(
        onSamples: () {
          if (!inDecoder.isCompleted) inDecoder.complete();
          return completeDecode.future;
        },
      );
      service = LiveRecitationService(
        engine: ZipformerEngine(openVerifiedNpuStream: () async => decoder),
        recorder: recorder,
        temporaryDirectory: () async => directory,
      );
      await service.prepare();
      final path = await service.start(
        onPartial: (_) =>
            fail('A failed capture must not publish partial text.'),
        onError: (error, _) => stopped.complete(error),
      );

      recorder.emit([1, 2]);
      await inDecoder.future;
      recorder.emit(Uint8List(64000));
      expect(await stopped.future, isA<StateError>());
      completeDecode.complete();
      await service.cancel();

      expect(await File(path).exists(), isFalse);
      expect(decoder.finishes, 0);
      expect(decoder.closes, 1);
      expect(recorder.cancels, 1);
    },
  );

  test(
    'simulates temporary slowdown: measures audio accumulation, alert latency, and verifies sample order preservation',
    () async {
      // 1. Setup a decoder that simulates backpressure (delays processing of early chunks)
      var decodeCalls = 0;
      final firstDecodeStarted = Completer<void>();
      final delayCompleter = Completer<void>();
      final partials = <String>[];

      final decoder = _Decoder(
        onSamples: () async {
          decodeCalls++;
          // Simulate temporary processing delay on the first chunk
          if (decodeCalls == 1) {
            if (!firstDecodeStarted.isCompleted) firstDecodeStarted.complete();
            await delayCompleter.future;
          }
        },
      );

      service = LiveRecitationService(
        engine: ZipformerEngine(openVerifiedNpuStream: () async => decoder),
        recorder: recorder,
        temporaryDirectory: () async => directory,
      );

      await service.prepare();
      final savedPath = await service.start(
        onPartial: partials.add,
        onError: failIfNotExpected,
      );

      // 2. Stream audio chunks (each chunk represents 100ms = 1600 samples = 3200 bytes)
      // We will emit 10 chunks = 1.0 second of audio (32,000 bytes total accumulation)
      const chunkCount = 10;
      const samplesPerChunk = 1600;
      final expectedSamples = <double>[];

      Uint8List makeChunk(int chunkIndex) {
        final byteData = ByteData(samplesPerChunk * 2);
        for (var s = 0; s < samplesPerChunk; s++) {
          final sampleVal = ((chunkIndex * samplesPerChunk + s) % 30000) - 15000;
          byteData.setInt16(s * 2, sampleVal, Endian.little);
          expectedSamples.add(
            sampleVal < 0 ? sampleVal / 32768.0 : sampleVal / 32767.0,
          );
        }
        return byteData.buffer.asUint8List();
      }

      // Emit first chunk and wait for decoder to pause inside it
      recorder.emit(makeChunk(0));
      await firstDecodeStarted.future;
      expect(decodeCalls, 1);

      // Emit remaining 9 chunks (28,800 bytes) while decoder is paused
      for (var c = 1; c < chunkCount; c++) {
        recorder.emit(makeChunk(c));
      }

      // At this point, chunk 1 is paused in decoder, and chunks 2..10 are queued in memory.
      // Accumulated queued bytes = 9 * 3200 = 28,800 bytes (~0.9s of audio queued).
      // Since 28,800 <= 64,000 (2s limit), capture remains healthy and does NOT crash.
      expect(decodeCalls, 1);

      // 3. Release the temporary slowdown (decoder catches up)
      final stopwatch = Stopwatch()..start();
      delayCompleter.complete();

      // Wait for all 10 chunks to be decoded in live stream
      while (decodeCalls < chunkCount) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      // Drain all queued chunks and finish the session
      final result = await service.finish();
      stopwatch.stop();

      // 4. Verification of sample order and data integrity:
      // a) Decoder processed all samples in exact FIFO sequence
      expect(decoder.samples.length, expectedSamples.length);
      for (var i = 0; i < expectedSamples.length; i++) {
        expect(
          decoder.samples[i],
          closeTo(expectedSamples[i], 1e-6),
          reason: 'Sample at index $i diverged in order or value',
        );
      }

      // b) WAV file recorded on disk has identical length and headers
      final wavBytes = await File(savedPath).readAsBytes();
      expect(wavBytes.length, 44 + (chunkCount * samplesPerChunk * 2));
      final wavHeader = ByteData.sublistView(wavBytes);
      expect(wavHeader.getUint32(24, Endian.little), 16000); // 16 kHz
      expect(wavHeader.getUint32(40, Endian.little), chunkCount * samplesPerChunk * 2);

      // c) Latency measurement:
      // Once the bottleneck cleared, all 10 chunks were processed rapidly
      expect(result.phonemes, 'final');
      expect(partials.length, chunkCount);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    },
  );
}
