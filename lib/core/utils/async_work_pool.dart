import 'dart:async';

/// Shares concurrent work without retaining results or failed requests.
class AsyncWorkPool<K, V> {
  final Map<K, Future<V>> _pending = {};

  Future<V> run(K key, Future<V> Function() load) {
    final existing = _pending[key];
    if (existing != null) return existing;
    final future = Future<V>.sync(load).whenComplete(() {
      _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }
}
