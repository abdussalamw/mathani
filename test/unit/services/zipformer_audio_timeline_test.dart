import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/services/recitation/zipformer_audio_timeline.dart';

void main() {
  test(
    'uses normalized word offsets and bounds the clip to captured audio',
    () {
      final timeline = ZipformerAudioTimeline('بۜحد', [
        (rawStart: 0, rawEnd: 1, startMs: 40, endMs: 120),
        (rawStart: 1, rawEnd: 2, startMs: 120, endMs: 160),
        (rawStart: 2, rawEnd: 4, startMs: 200, endMs: 420),
      ], 400);

      expect(timeline.clip(0, 1), (startMs: 0, endMs: 280));
      expect(timeline.clip(1, 3), (startMs: 60, endMs: 400));
    },
  );

  test('omits clips without valid audio boundaries', () {
    final timeline = ZipformerAudioTimeline('بحد', [
      (rawStart: 0, rawEnd: 1, startMs: 0, endMs: 40),
      (rawStart: 1, rawEnd: 2, startMs: 100, endMs: 140),
      (rawStart: 2, rawEnd: 3, startMs: 220, endMs: 260),
      (rawStart: 3, rawEnd: 4, startMs: 40, endMs: 80),
    ], 200);

    expect(timeline.clip(null, 2), isNull);
    expect(timeline.clip(2, 3), isNull);
    expect(timeline.clip(0, 4), isNull);
  });
}
