import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:meta/meta.dart';

/// Last-seen page/floor per thread (Hive).
class ThreadReadingPositionStore {
  ThreadReadingPositionStore._();

  static final ThreadReadingPositionStore instance =
      ThreadReadingPositionStore._();

  static const String boxName = 'thread_reading_positions';

  static const int maxEntries = 200;

  @visibleForTesting
  static Duration persistDebounce = const Duration(seconds: 1);

  Box get _box => Hive.box(boxName);

  final Map<int, ThreadReadingPosition> _latest = {};
  final Map<int, Timer> _debounceTimers = {};

  ThreadReadingPosition? get(int threadId) {
    final cached = _latest[threadId];
    if (cached != null) {
      return cached;
    }
    final raw = _box.get(threadId.toString());
    if (raw is Map) {
      return ThreadReadingPosition.fromMap(raw);
    }
    return null;
  }

  Future<void> save(
    int threadId, {
    required int page,
    required int floor,
  }) async {
    final safeFloor = floor < 1 ? 1 : floor;
    final safePage = page < 1 ? 1 : page;
    final existing = get(threadId);
    if (existing != null &&
        existing.page == safePage &&
        existing.floor == safeFloor) {
      return;
    }
    _latest[threadId] = ThreadReadingPosition(
      page: safePage,
      floor: safeFloor,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _debounceTimers[threadId]?.cancel();
    _debounceTimers[threadId] = Timer(persistDebounce, () {
      _debounceTimers.remove(threadId);
      _persist(threadId);
    });
  }

  /// Writes pending debounced positions now (dispose / app pause).
  Future<void> flush() async {
    final ids = _debounceTimers.keys.toList();
    for (final id in ids) {
      _debounceTimers.remove(id)?.cancel();
      await _persist(id);
    }
  }

  Future<void> _persist(int threadId) async {
    final position = _latest[threadId];
    if (position == null) {
      return;
    }
    await _box.put(threadId.toString(), position.toMap());
    await _evictOldestIfNeeded();
  }

  @visibleForTesting
  void resetForTest() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _latest.clear();
  }

  Future<void> _evictOldestIfNeeded() async {
    if (_box.length <= maxEntries) {
      return;
    }
    final entries = <MapEntry<dynamic, ThreadReadingPosition>>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        entries.add(MapEntry(key, ThreadReadingPosition.fromMap(raw)));
      }
    }
    entries.sort((a, b) => a.value.updatedAtMs.compareTo(b.value.updatedAtMs));
    final overflow = entries.length - maxEntries;
    if (overflow <= 0) {
      return;
    }
    for (var i = 0; i < overflow; i++) {
      await _box.delete(entries[i].key);
    }
  }
}
