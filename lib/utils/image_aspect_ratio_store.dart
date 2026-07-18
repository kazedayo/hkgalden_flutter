import 'package:hive/hive.dart';

/// Persists decoded image height/width ratios keyed by URL (Hive box of maps).
class ImageAspectRatioStore {
  ImageAspectRatioStore._();

  static final ImageAspectRatioStore instance = ImageAspectRatioStore._();

  static const String boxName = 'image_aspect_ratios';

  static const int maxEntries = 500;

  /// Fallback height/width when no intrinsic size or cache entry exists.
  static const double fallbackAspectRatio = 3 / 4;

  Box get _box => Hive.box(boxName);

  static bool isValidAspectRatio(double ratio) =>
      ratio.isFinite && ratio > 0;

  static double? aspectRatioFromSize(double width, double height) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return null;
    }
    final ratio = height / width;
    return isValidAspectRatio(ratio) ? ratio : null;
  }

  double? aspectRatio(String url) {
    if (url.isEmpty) {
      return null;
    }
    final raw = _box.get(url);
    if (raw is Map) {
      final r = (raw['r'] as num?)?.toDouble();
      if (r != null && isValidAspectRatio(r)) {
        return r;
      }
    }
    return null;
  }

  Future<void> save(String url, double aspectRatio) async {
    if (url.isEmpty || !isValidAspectRatio(aspectRatio)) {
      return;
    }
    await _box.put(url, {
      'r': aspectRatio,
      't': DateTime.now().millisecondsSinceEpoch,
    });
    await _evictOldestIfNeeded();
  }

  Future<void> _evictOldestIfNeeded() async {
    if (_box.length <= maxEntries) {
      return;
    }
    final entries = <MapEntry<dynamic, int>>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      final t = raw is Map ? (raw['t'] as num?)?.toInt() ?? 0 : 0;
      entries.add(MapEntry(key, t));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));
    final overflow = entries.length - maxEntries;
    if (overflow <= 0) {
      return;
    }
    for (var i = 0; i < overflow; i++) {
      await _box.delete(entries[i].key);
    }
  }
}
