import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathani/core/utils/async_work_pool.dart';

void main() {
  test('concurrent callers share work and later requests can reload', () async {
    final pool = AsyncWorkPool<int, int>();
    final pending = Completer<int>();
    var calls = 0;
    Future<int> load() {
      calls++;
      return pending.future;
    }

    final first = pool.run(1, load);
    final second = pool.run(1, load);
    expect(identical(first, second), isTrue);
    pending.complete(42);
    expect(await first, 42);
    expect(await second, 42);
    expect(calls, 1);
    expect(await pool.run(1, () async => 7), 7);
  });

  test('failed and synchronous loaders are released for retry', () async {
    final pool = AsyncWorkPool<String, int>();
    await expectLater(
      pool.run('page', () => throw StateError('missing font')),
      throwsStateError,
    );
    expect(await pool.run('page', () async => 1), 1);
  });
}
