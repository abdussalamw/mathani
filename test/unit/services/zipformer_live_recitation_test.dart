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
    return 'partial';
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
          inDecoder.complete();
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
}
