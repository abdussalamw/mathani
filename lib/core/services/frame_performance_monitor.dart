import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class FramePerformanceMonitor {
  static final instance = FramePerformanceMonitor._();
  FramePerformanceMonitor._();
  final List<int> _build = [];
  final List<int> _raster = [];
  bool _started = false;

  void start() {
    if (_started || !const bool.fromEnvironment('MATHANI_PERFORMANCE')) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_record);
  }

  void _record(List<FrameTiming> timings) {
    for (final timing in timings) {
      _build.add(timing.buildDuration.inMicroseconds);
      _raster.add(timing.rasterDuration.inMicroseconds);
      if (_build.length == 120) {
        debugPrint(
          'MATHANI_PERFORMANCE ${jsonEncode({'frames': _build.length, 'buildP95Us': _percentile(_build), 'rasterP95Us': _percentile(_raster), 'over16ms': List.generate(_build.length, (i) => i).where((i) => _build[i] > 16667 || _raster[i] > 16667).length, 'over8ms': List.generate(_build.length, (i) => i).where((i) => _build[i] > 8333 || _raster[i] > 8333).length})}',
        );
        _build.clear();
        _raster.clear();
      }
    }
  }

  int _percentile(List<int> values) {
    final sorted = [...values]..sort();
    return sorted[((sorted.length - 1) * .95).ceil()];
  }
}
