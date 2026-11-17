import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/utils/reader_swipe_policy.dart';

void main() {
  int? target(double offset, Axis axis, {int page = 3}) =>
      ReaderSwipePolicy.targetPage(
        page: page,
        pageCount: 5,
        offset: offset,
        primaryAxis: axis,
      );

  test('vertical swipes move forward up and backward down', () {
    expect(target(-100, Axis.horizontal), 4);
    expect(target(100, Axis.horizontal), 2);
  });
  test('horizontal swipes respect right-to-left reading', () {
    expect(target(100, Axis.vertical), 4);
    expect(target(-100, Axis.vertical), 2);
  });
  test('page edges and cancelled movement never wrap around', () {
    expect(target(-100, Axis.horizontal, page: 5), isNull);
    expect(target(100, Axis.horizontal, page: 1), isNull);
    expect(target(0, Axis.vertical), isNull);
    expect(
      ReaderSwipePolicy.shouldCommit(offset: 30, velocity: 0, extent: 800),
      isFalse,
    );
    expect(
      ReaderSwipePolicy.shouldCommit(offset: 120, velocity: -700, extent: 800),
      isFalse,
    );
    expect(
      ReaderSwipePolicy.shouldCommit(offset: 30, velocity: 700, extent: 800),
      isTrue,
    );
  });
}
