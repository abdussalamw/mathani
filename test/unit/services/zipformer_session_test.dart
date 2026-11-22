import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/database/isar_service.dart';
import 'package:mathani/core/services/recitation/live_recitation_service.dart';
import 'package:mathani/core/services/recitation/recitation_phoneme_repository.dart';
import 'package:mathani/core/services/recitation/zipformer_engine.dart';
import 'package:mathani/data/models/recitation_result.dart';
import 'package:mathani/data/models/recitation_session.dart';
import 'package:mathani/data/services/audio_recorder_service.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/presentation/providers/recitation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/isar_test_core.dart';

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
  String transcript;
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
        '12:2': {
          'aya_text': 'fourth fifth sixth',
          'aya_phoneme': 'pqrstuvwxyzaabc',
          'aya_phonemes_list': ['pqrst', 'uvwxy', 'zaabc'],
          'suraname_ar': 'سورة الاختبار',
          'suraname_en': 'Test',
          'rules': [],
        },
        '12:3': {
          'aya_text': 'seventh eighth ninth',
          'aya_phoneme': 'bcedfhgikjlnomp',
          'aya_phonemes_list': ['bcedf', 'hgikj', 'lnomp'],
          'suraname_ar': 'سورة الاختبار',
          'suraname_en': 'Test',
          'rules': [],
        },
        '23:8': {
          'aya_text': 'alpha bravo charlie delta echo foxtrot golf hotel',
          'aya_phoneme': 'alphabravocharliedeltaechofoxtrotgolfhotel',
          'aya_phonemes_list': [
            'alpha',
            'bravo',
            'charlie',
            'delta',
            'echo',
            'foxtrot',
            'golf',
            'hotel',
          ],
          'suraname_ar': 'سورة الاختبار',
          'suraname_en': 'Test',
          'rules': [],
        },
      });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

  Future<void> hear(_Decoder decoder, String words) async {
    decoder.transcript = words;
    final processed = Completer<void>();
    void check() {
      if (provider.liveTranscript == words && !processed.isCompleted) {
        processed.complete();
      }
    }

    provider.addListener(check);
    try {
      recorder.emitSample();
      await processed.future.timeout(const Duration(seconds: 3));
    } finally {
      provider.removeListener(check);
    }
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

  test('resumes live at the next ayah and reports unconfirmed words', () async {
    create(() async => _Decoder('${transcript}pqrstuvwxyzaxbcedfhgikj'));
    expect(await provider.startRecording(), isNotNull);
    expect(provider.liveReadingStatus, 'جارٍ فتح الميكروفون...');
    final advanced = Completer<void>();
    void checkPosition() {
      if (provider.matchedAyah == 3 && !advanced.isCompleted) {
        advanced.complete();
      }
    }

    provider.addListener(checkPosition);
    try {
      recorder.emitSample();
      await advanced.future.timeout(const Duration(seconds: 3));
      expect(provider.liveWordVerdicts['12_2_3'], WordVerdict.unconfirmed);
      expect(provider.liveWordVerdicts['12_3_1'], WordVerdict.correct);
      expect(provider.mistakesCount, 0);
      expect(provider.liveReadingStatus, endsWith('seventh eighth'));
    } finally {
      provider.removeListener(checkPosition);
    }

    await provider.stopRecording();
    final result = provider.currentResult!;
    expect(result.endAyah, 3);
    expect(result.gradedWords, 7);
    expect(result.unconfirmedWords, 2);
    expect(result.skippedWords, 0);
    expect(result.incorrectWords, 0);
    expect(result.accuracyPercent, 100);
    expect(
      result.words
          .where((word) => word.verdict == WordVerdict.unconfirmed)
          .map((word) => word.expectedWord),
      ['sixth', 'ninth'],
    );
    expect(provider.saved.single.totalWords, result.gradedWords);
  });

  test(
    'live text and prompt follow an ayah replay without losing results',
    () async {
      const opening = 'alphabravocharliedelta';
      const firstAttempt = '${opening}ecxofoxtrotgolf';
      const replay = '${firstAttempt}charliedelta';
      final decoder = _Decoder(opening);
      create(() async => decoder);
      expect(await provider.startRecording(), isNotNull);

      await hear(decoder, opening);
      await hear(decoder, firstAttempt);
      expect(provider.getNextWord(), 'hotel');
      expect(provider.liveWordVerdicts['23_8_5'], WordVerdict.incorrect);

      await hear(decoder, replay);
      expect(provider.liveReadingStatus, 'alpha bravo charlie delta');
      expect(provider.getNextWord(), 'echo');
      expect(provider.liveWordVerdicts['23_8_5'], WordVerdict.incorrect);
      expect(provider.liveWordVerdicts['23_8_7'], WordVerdict.correct);

      await hear(decoder, '${replay}echofoxtrotgolfhotel');
      await provider.stopRecording();
      final words = provider.currentResult!.words;
      expect(words, hasLength(8));
      final correction = words.singleWhere(
        (word) => word.reviewKind == RecitationReviewKind.corrected,
      );
      expect(correction.expectedWord, 'echo');
      expect(correction.verdict, WordVerdict.correct);
    },
  );

  test('hidden words follow confirmed reads and a strict correction', () async {
    const opening = 'alphabravocharliedelta';
    const mistaken = '${opening}ecxofoxtrotgolf';
    final decoder = _Decoder(opening);
    create(() async => decoder);
    expect(provider.hideVerses, isFalse);
    expect(provider.stopOnConfirmedError, isFalse);
    provider.setHideVerses(true);
    provider.setStopOnConfirmedError(true);
    expect(await provider.startRecording(), isNotNull);
    expect(provider.revealedWordKeys, isEmpty);

    await hear(decoder, opening);
    const revealed = {'23_8_1', '23_8_2', '23_8_3', '23_8_4'};
    expect(provider.revealedWordKeys, revealed);

    await hear(decoder, mistaken);
    expect(provider.liveReadingStatus, contains('أعد الكلمة'));
    expect(provider.revealedWordKeys, revealed);
    provider.triggerPrompt();
    expect(provider.promptWord, 'echo');
    expect(provider.revealedWordKeys, revealed);

    provider.toggleVerseVisibility();
    expect(provider.hideVerses, isFalse);
    provider.toggleVerseVisibility();
    expect(provider.hideVerses, isTrue);
    expect(provider.isRecording, isTrue);
    expect(provider.revealedWordKeys, revealed);

    await hear(decoder, '${mistaken}charliedeltaechofoxtrotgolfhotel');
    expect(provider.revealedWordKeys, {
      for (var index = 1; index <= 8; index++) '23_8_$index',
    });
    expect(provider.liveReadingStatus, isNot(contains('أعد الكلمة')));
    expect(recorder.starts, 1);

    await provider.stopRecording();
    expect(provider.revealedWordKeys, isEmpty);
    expect(
      provider.currentResult?.reviewItems.single.kind,
      RecitationReviewKind.corrected,
    );
  });

  test(
    'review dismissal persists and can be restored after reopening',
    () async {
      create();
      await initializeTestIsar();
      final service = IsarService.instance;
      await service.init(directory: directory.path);
      try {
        final result = RecitationResult(
          words: const [
            WordResult(
              spokenWord: 'مختلف',
              expectedWord: 'المحفوظ',
              surahNumber: 12,
              ayahNumber: 1,
              wordIndex: 0,
              verdict: WordVerdict.incorrect,
              confidence: 0.5,
              startTimeMs: 400,
              endTimeMs: 900,
            ),
          ],
          surahNumber: 12,
          surahName: 'يوسف',
          startAyah: 1,
          endAyah: 1,
          durationMs: 900,
          rawTranscript: 'synthetic',
          audioPath: 'synthetic.wav',
        );
        final record = RecitationSession()
          ..surahNumber = 12
          ..accuracyPercent = result.accuracyPercent
          ..totalWords = 1
          ..resultJson = jsonEncode(result.toJson());
        record.id = await service.isar.writeTxn(
          () => service.isar.recitationSessions.put(record),
        );
        final original = RecitationResult.fromSession(record);
        final dismissed = await provider.setReviewItemDismissed(
          original,
          original.reviewItems.single,
          dismissed: true,
        );
        expect(dismissed.reviewIssueCount, 0);
        expect(dismissed.accuracyPercent, original.accuracyPercent);
        expect(dismissed.audioPath, result.audioPath);
        expect(dismissed.words.single.startTimeMs, 400);

        await service.close();
        await service.init(directory: directory.path);
        await provider.loadSessions();
        final reopened = RecitationResult.fromSession(
          provider.allSessions.single,
        );
        expect(reopened.reviewIssueCount, 0);
        final restored = await provider.setReviewItemDismissed(
          reopened,
          reopened.reviewItems.single,
          dismissed: false,
        );
        expect(restored.reviewIssueCount, 1);
      } finally {
        await service.close();
      }
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
