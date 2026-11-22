import 'dart:typed_data';

import '../../utils/phoneme_utils.dart';
import 'zipformer_engine.dart';

/// Maps normalized transcript offsets to approximate clips in the same WAV.
class ZipformerAudioTimeline {
  ZipformerAudioTimeline(
    String raw,
    Iterable<ZipformerTokenTiming> tokens,
    this._durationMs,
  ) {
    final offsets = Int32List(raw.length + 1);
    for (var i = 0; i < raw.length; i++) {
      offsets[i + 1] =
          offsets[i] +
          (PhonemeUtils.isZeroCostMarker(raw.codeUnitAt(i)) ? 0 : 1);
    }
    _starts = Int32List(offsets.last);
    _ends = Int32List(offsets.last);
    for (final token in tokens) {
      if (token.rawStart < 0 ||
          token.rawEnd <= token.rawStart ||
          token.rawEnd > raw.length ||
          token.startMs < 0 ||
          token.startMs >= _durationMs ||
          token.endMs <= token.startMs) {
        continue;
      }
      final end = token.endMs.clamp(0, _durationMs);
      for (var i = offsets[token.rawStart]; i < offsets[token.rawEnd]; i++) {
        _starts[i] = token.startMs + 1;
        _ends[i] = end;
      }
    }
  }

  final int _durationMs;
  late final Int32List _starts;
  late final Int32List _ends;

  ({int startMs, int endMs})? clip(int? start, int? end) {
    if (start == null ||
        end == null ||
        start < 0 ||
        end <= start ||
        end > _ends.length) {
      return null;
    }
    final encodedFirst = _starts[start];
    final last = _ends[end - 1];
    if (encodedFirst == 0 || last < encodedFirst) return null;
    // CTC steps locate the word approximately. Include short audible context.
    return (
      startMs: (encodedFirst - 1 - 140).clamp(0, _durationMs),
      endMs: (last + 160).clamp(0, _durationMs),
    );
  }
}
