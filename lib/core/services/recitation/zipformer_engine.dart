import 'dart:typed_data';

/// Implementations verify that the entire model runs on the NPU, with fallback
/// disabled, before returning a stream. Decoder work must stay off the UI isolate.
abstract interface class ZipformerNpuStream {
  /// Returns the cumulative transcription, or an empty string when unchanged.
  Future<String> acceptPcm(Float32List samples);
  Future<String> finish();
  Future<void> close();
}

/// Approximate positions from the CTC frames, in raw transcript code units and
/// milliseconds of the shared PCM stream.
typedef ZipformerTokenTiming = ({
  int rawStart,
  int rawEnd,
  int startMs,
  int endMs,
});

abstract interface class ZipformerTimedNpuStream implements ZipformerNpuStream {
  Future<List<ZipformerTokenTiming>> readTokenTimings();
}

class ZipformerNpuUnavailable implements Exception {
  const ZipformerNpuUnavailable([
    this.message = 'هذه النسخة من مثاني لم تُجهّز لتشغيل Zipformer على NPU.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class ZipformerEngine {
  const ZipformerEngine({this.openVerifiedNpuStream});

  final Future<ZipformerNpuStream> Function()? openVerifiedNpuStream;

  // The bundled runtime cannot enforce NPU-only inference. A verified native
  // adapter must be supplied by the platform before recording is enabled.
  bool get isNpuSupported => openVerifiedNpuStream != null;

  Future<ZipformerNpuStream> openStream() async {
    final open = openVerifiedNpuStream;
    if (open == null) throw const ZipformerNpuUnavailable();
    return open();
  }
}
