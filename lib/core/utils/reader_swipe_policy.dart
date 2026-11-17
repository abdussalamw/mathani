import 'package:flutter/widgets.dart';

class ReaderSwipePolicy {
  static int? targetPage({
    required int page,
    required int pageCount,
    required double offset,
    required Axis primaryAxis,
    TextDirection direction = TextDirection.rtl,
  }) {
    if (offset == 0 || pageCount < 1) return null;
    final next = primaryAxis == Axis.horizontal
        ? offset < 0
        : (direction == TextDirection.rtl ? offset > 0 : offset < 0);
    final target = (page + (next ? 1 : -1)).clamp(1, pageCount);
    return target == page ? null : target;
  }

  static bool shouldCommit({
    required double offset,
    required double velocity,
    required double extent,
  }) {
    if (extent <= 0 || offset == 0) return false;
    if (velocity.abs() > 550 && velocity.sign != offset.sign) return false;
    return offset.abs() >= extent * .12 || velocity.abs() > 550;
  }
}
