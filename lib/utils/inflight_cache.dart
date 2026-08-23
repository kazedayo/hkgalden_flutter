class InflightCache<K, V> {
  final Map<K, V> _resolved = {};
  final Map<K, Future<V>> _inflight = {};

  /// Cached value for [key], or null when absent.
  V? peek(K key) => _resolved[key];

  Future<V> get(K key, Future<V> Function() load, {bool cacheNulls = true}) {
    if (_resolved.containsKey(key)) {
      return Future<V>.value(_resolved[key] as V);
    }
    return _inflight.putIfAbsent(key, () async {
      final value = await load();
      _inflight.remove(key);
      if (cacheNulls || value != null) {
        _resolved[key] = value;
      }
      return value;
    });
  }

  void clear() {
    _inflight.clear();
    _resolved.clear();
  }
}
