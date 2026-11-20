import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/live_recitation_service.dart';
import 'package:mathani/core/services/recitation/recitation_phoneme_repository.dart';
import 'package:mathani/core/services/recitation/zipformer_engine.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/data/services/audio_recorder_service.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';

class _QuranRepository extends Fake implements QuranRepository {}

class _Recorder implements RecitationAudioRecorder {
  StreamController<Uint8List>? _audio;
  Future<void> Function()? beforeOpen;
  int permissionChecks = 0;
  int starts = 0;
  int stops = 0;
  int cancels = 0;
  bool permission = true;

  @override
  Future<bool> hasPermission({bool request = false}) async {
    permissionChecks++;
    return permission;
  }

  @override
  Future<Stream<Uint8List>> startPcm() async {
    starts++;
    await beforeOpen?.call();
    _audio = StreamController<Uint8List>();
    return _audio!.stream;
  }

  void emitSample() => _audio!.add(Uint8List.fromList([1, 2]));

  @override
  Future<void> stop() async {
    stops++;
    await _audio?.close();
  }

  @override
  Future<void> cancel() async {
    cancels++;
    final audio = _audio;
    if (audio != null && !audio.isClosed) {
      if (audio.hasListener) {
        await audio.close();
      } else {
        unawaited(audio.close());
      }
    }
  }

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
  _Decoder(this.transcript, {this.complete});
  final String transcript;
  final Future<String> Function()? complete;
  int closes = 0;

  @override
  Future<String> acceptPcm(Float32List samples) async => transcript;

  @override
  Future<String> finish() async => complete == null ? transcript : complete!();

  @override
  Future<void> close() async {
    closes++;
  }
}

class _Provider extends RecitationProvider {
  _Provider(LiveRecitationService service, RecitationPhonemeRepository repo)
    : super(
        liveService: service,
        phonemeRepository: repo,
        quranRepository: _QuranRepository(),
        loadInitialState: false,
      );

  final saved = <RecitationSession>[];

  @override
  Future<void> saveSession(RecitationSession session) async {
    saved.add(session);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late RecitationPhonemeRepository repo;
  late _Recorder recorder;
  late _Provider provider;
  late LiveRecitationService service;
  const transcript = 'abcdefghijklmno';

  setUpAll(() {
    repo = RecitationPhonemeRepository()
      ..loadForTesting({
        '12:1': {
          'aya_text': 'first second third',
          'aya_phoneme': transcript,
          'aya_phonemes_list': ['abcde', 'fghij', 'klmno'],
          'suraname_ar': 'سورة الاختبار',
          'suraname_en': 'Test',
          'rules': [],
        },
      });
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mathani-session-test-');
    recorder = _Recorder();
  });

  void create([Future<ZipformerNpuStream> Function()? open]) {
    service = LiveRecitationService(
      engine: ZipformerEngine(openVerifiedNpuStream: open),
      recorder: recorder,
      temporaryDirectory: () async => directory,
    );
    provider = _Provider(service, repo);
  }

  tearDown(() async {
    await provider.cancelRecording();
    provider.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'default gates both start paths before requesting microphone permission',
    () async {
      create();
      expect(await provider.startRecording(), isNull);
      expect(await provider.startRecitationFromMinibar(), isNull);
      expect(provider.errorMessage, contains('NPU'));
      expect(recorder.permissionChecks, 0);
      expect(recorder.starts, 0);
      expect(provider.saved, isEmpty);
    },
  );

  test(
    'a second tap or a cancelled preparation cannot open the microphone',
    () async {
      final opening = Completer<void>();
      final pending = Completer<ZipformerNpuStream>();
      final decoder = _Decoder(transcript);
      create(() {
        opening.complete();
        return pending.future;
      });
      final first = provider.startRecitationFromMinibar();
      await opening.future;
      expect(provider.state, RecitationState.preparing);
      expect(await provider.startRecording(), isNull);
      final cancelled = provider.cancelRecording();
      expect(await provider.startRecording(), isNull);
      pending.complete(decoder);
      expect(await first, isNull);
      await cancelled;
      expect(recorder.starts, 0);
      expect(decoder.closes, 1);
      expect(provider.state, RecitationState.setup);
      expect(provider.saved, isEmpty);
    },
  );

  test(
    'permission denial closes the prepared decoder without recording',
    () async {
      recorder.permission = false;
      final decoder = _Decoder(transcript);
      create(() async => decoder);
      expect(await provider.startRecording(), isNull);
      expect(provider.errorMessage, contains('إذن الميكروفون'));
      expect(recorder.starts, 0);
      expect(decoder.closes, 1);
    },
  );

  test(
    'cancellation during microphone startup releases the late recorder',
    () async {
      final begun = Completer<void>();
      final permitOpen = Completer<void>();
      recorder.beforeOpen = () {
        begun.complete();
        return permitOpen.future;
      };
      create(() async => _Decoder(transcript));
      final started = provider.startRecording();
      await begun.future;
      final cancelled = provider.cancelRecording();
      permitOpen.complete();
      expect(await started, isNull);
      await cancelled;
      expect(recorder.starts, 1);
      expect(recorder.cancels, 1);
      expect(provider.isRecording, isFalse);
      expect(directory.listSync(), isEmpty);
    },
  );

  test(
    'commits one real result and a later cancellation preserves its recording',
    () async {
      create(() async => _Decoder(transcript));
      final path = (await provider.startRecitationFromMinibar())!;
      recorder.emitSample();
      final stop = provider.stopRecording();
      await provider.stopRecording();
      await stop;
      expect(provider.state, RecitationState.result);
      expect(provider.saved.single.surahNumber, 12);
      expect(provider.saved.single.totalWords, greaterThan(0));
      expect(provider.currentResult!.audioPath, path);
      expect(await File(path).exists(), isTrue);

      final discarded = (await provider.startRecording())!;
      await provider.cancelRecording();
      expect(await File(path).exists(), isTrue);
      expect(await File(discarded).exists(), isFalse);
      expect(provider.saved, hasLength(1));
    },
  );

  test(
    'does not grade an empty recording even if the decoder returns words',
    () async {
      create(() async => _Decoder(transcript));
      final path = (await provider.startRecording())!;
      await provider.stopRecording();
      expect(provider.state, RecitationState.error);
      expect(provider.currentResult, isNull);
      expect(provider.saved, isEmpty);
      expect(await File(path).exists(), isFalse);
    },
  );

  test('cancelling finalization discards its late transcript and permits a fresh session', () async {
    final finalizing = Completer<void>();
    final response = Completer<String>();
    var streams = 0;
    create(() async {
      streams++;
      return _Decoder(
        transcript,
        complete: streams != 1
            ? null
            : () {
                finalizing.complete();
                return response.future;
              },
      );
    });
    final path = (await provider.startRecording())!;
    recorder.emitSample();
    final stopped = provider.stopRecording();
    await finalizing.future;
    final cancelled = provider.cancelRecording();
    expect(await provider.startRecording(), isNull);
    response.complete(transcript);
    await Future.wait([cancelled, stopped]);
    expect(provider.currentResult, isNull);
    expect(provider.saved, isEmpty);
    expect(await File(path).exists(), isFalse);
    expect(await provider.startRecording(), isNotNull);
  });
}
