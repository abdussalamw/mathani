import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mathani/core/errors/failures.dart';
import 'package:mathani/data/models/reciter.dart';
import 'package:mathani/data/models/surah.dart';
import 'package:mathani/data/repositories/reciter_repository.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/presentation/providers/audio_provider.dart';

class _Player implements AudioPlayer {
  final indices = StreamController<int?>.broadcast(sync: true);
  final states = StreamController<ProcessingState>.broadcast(sync: true);
  List<AudioSource> sources = [];
  int plays = 0;
  bool? preloadValue;
  int? initialIndexValue;
  Duration? initialPositionValue;
  bool playingValue = false;
  int? indexValue = 0;
  Completer<void>? playback;
  @override
  bool get playing => playingValue;
  @override
  int? get currentIndex => indexValue;
  @override
  Duration get position => const Duration(seconds: 12);

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Stream<ProcessingState> get processingStateStream => states.stream;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    sources = audioSources;
    preloadValue = preload;
    initialIndexValue = initialIndex;
    initialPositionValue = initialPosition;
    return null;
  }

  @override
  Future<void> play() async {
    plays++;
    if (playback != null) await playback!.future;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    await indices.close();
    await states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reciters implements ReciterRepository {
  @override
  Future<List<Reciter>> getReciters() async => [
    Reciter(
      id: 'test',
      name: 'قارئ الاختبار',
      style: 'Murattal',
      bitrate: '128kbps',
    ),
  ];
}

class _Quran implements QuranRepository {
  @override
  Future<Either<Failure, Surah?>> getSurahByNumber(int number) async => Right(
    Surah()
      ..number = number
      ..nameArabic = 'سورة الاختبار'
      ..numberOfAyahs = 3,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Player player;
  late AudioProvider provider;
  setUp(() async {
    player = _Player();
    provider = AudioProvider(
      player: player,
      quranRepository: _Quran(),
      reciterRepository: _Reciters(),
    );
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() {
    provider.dispose();
  });

  test(
    'preserves verse order, repetition, metadata and lazy playlist setup',
    () async {
      provider.setAyahRepeatLimit(2);
      provider.setRangeRepeatLimit(2);
      await provider.playRange(
        startSurah: 1,
        startAyah: 2,
        endSurah: 2,
        endAyah: 1,
      );
      final tags = player.sources
          .cast<UriAudioSource>()
          .map((source) => source.tag as MediaItem)
          .toList();
      expect(tags.map((tag) => tag.id), [
        '1_2_0',
        '1_2_1',
        '1_3_2',
        '1_3_3',
        '2_1_4',
        '2_1_5',
        '1_2_6',
        '1_2_7',
        '1_3_8',
        '1_3_9',
        '2_1_10',
        '2_1_11',
      ]);
      expect(tags.first.artist, 'قارئ الاختبار');
      expect(
        (player.sources.first as UriAudioSource).uri.path,
        '/data/test/001002.mp3',
      );
      expect(player.preloadValue, isFalse);
      expect(player.initialIndexValue, 0);
      expect(player.plays, 1);
      expect(provider.lastError, isNull);
    },
  );

  test('loading ends before playback completes', () async {
    player.playback = Completer<void>();
    await provider.playRange(
      startSurah: 1,
      startAyah: 1,
      endSurah: 1,
      endAyah: 3,
    );
    expect(provider.isLoading, isFalse);
    expect(player.plays, 1);
    player.playback!.complete();
  });

  test('live range update keeps the verse and playback position', () async {
    await provider.playRange(
      startSurah: 1,
      startAyah: 1,
      endSurah: 1,
      endAyah: 3,
    );
    player.indices.add(1);
    player.playingValue = true;
    provider.setAyahRepeatLimit(2);
    await provider.playRange(
      startSurah: 1,
      startAyah: 1,
      endSurah: 1,
      endAyah: 3,
      preserveCurrentPosition: true,
    );
    expect(player.initialIndexValue, 2);
    expect(player.initialPositionValue, const Duration(seconds: 12));
    expect(provider.currentAyah, 2);
    expect(player.plays, 2);
  });

  test('live update preserves pause and rejects invalid ranges', () async {
    await provider.playRange(
      startSurah: 1,
      startAyah: 1,
      endSurah: 1,
      endAyah: 3,
    );
    await provider.playRange(
      startSurah: 1,
      startAyah: 2,
      endSurah: 1,
      endAyah: 3,
      preserveCurrentPosition: true,
    );
    expect(player.plays, 1);
    expect(player.initialPositionValue, Duration.zero);
    await provider.playRange(
      startSurah: 2,
      startAyah: 2,
      endSurah: 1,
      endAyah: 3,
    );
    expect(provider.lastError, isNotNull);
    expect(player.plays, 1);
  });

  test('updates the active verse from the modern playlist index', () async {
    await provider.playRange(
      startSurah: 1,
      startAyah: 2,
      endSurah: 2,
      endAyah: 1,
    );
    player.indices.add(2);
    expect(provider.currentSurah, 2);
    expect(provider.currentAyah, 1);
    player.states.add(ProcessingState.completed);
    player.indices.add(0);
    expect(provider.currentSurah, 2);
    expect(provider.isPlaying, isFalse);
  });
}
