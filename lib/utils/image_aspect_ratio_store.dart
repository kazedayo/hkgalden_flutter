import 'package:hive/hive.dart';

/// Persists decoded image height/width ratios (and optional natural widths)
/// keyed by URL (Hive box of maps).
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

  static bool isValidNaturalWidth(double width) =>
      width.isFinite && width > 0;

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

  /// Natural image width in logical/CSS-style pixels (from `data-sx` or decode).
  double? naturalWidth(String url) {
    if (url.isEmpty) {
      return null;
    }
    final raw = _box.get(url);
    if (raw is Map) {
      final w = (raw['w'] as num?)?.toDouble();
      if (w != null && isValidNaturalWidth(w)) {
        return w;
      }
    }
    return null;
  }

  Future<void> save(
    String url,
    double aspectRatio, {
    double? naturalWidth,
  }) async {
    if (url.isEmpty || !isValidAspectRatio(aspectRatio)) {
      return;
    }
    final existing = _box.get(url);
    double? width = naturalWidth;
    if (width == null && existing is Map) {
      final w = (existing['w'] as num?)?.toDouble();
      if (w != null && isValidNaturalWidth(w)) {
        width = w;
      }
    }
    final map = <String, dynamic>{
      'r': aspectRatio,
      't': DateTime.now().millisecondsSinceEpoch,
    };
    if (width != null && isValidNaturalWidth(width)) {
      map['w'] = width;
    }
    await _box.put(url, map);
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
