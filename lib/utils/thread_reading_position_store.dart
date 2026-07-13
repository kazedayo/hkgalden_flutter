import 'package:hive/hive.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';

/// Persists per-thread last-seen page + floor across app launches.
///
/// Uses a Hive box of plain maps (no type adapter) keyed by thread id string.
class ThreadReadingPositionStore {
  ThreadReadingPositionStore._();

  static final ThreadReadingPositionStore instance =
      ThreadReadingPositionStore._();

  static const String boxName = 'thread_reading_positions';

  /// Soft cap so the box does not grow without bound.
  static const int maxEntries = 200;

  Box get _box => Hive.box(boxName);

  ThreadReadingPosition? get(int threadId) {
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
    await _box.put(
      threadId.toString(),
      ThreadReadingPosition(
        page: safePage,
        floor: safeFloor,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ).toMap(),
    );
    await _evictOldestIfNeeded();
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
