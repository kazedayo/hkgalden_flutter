class InflightCache<K, V> {
  final Map<K, V> _resolved = {};
  final Map<K, Future<V>> _inflight = {};

  Future<V> get(K key, Future<V> Function() load) {
    if (_resolved.containsKey(key)) {
      return Future<V>.value(_resolved[key] as V);
    }
    return _inflight.putIfAbsent(key, () async {
      final value = await load();
      _resolved[key] = value;
      _inflight.remove(key);
      return value;
    });
  }

  void clear() {
    _inflight.clear();
    _resolved.clear();
  }
}
