import 'package:hive_flutter/hive_flutter.dart';

/// Hive cache of image aspect ratios (and optional natural widths) by URL.
class ImageAspectRatioStore {
  ImageAspectRatioStore._();

  static final ImageAspectRatioStore instance = ImageAspectRatioStore._();

  static const String boxName = 'image_aspect_ratios';

  static const int maxEntries = 500;

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
    if (_unchanged(existing, aspectRatio, naturalWidth)) {
      return;
    }
    double? width = naturalWidth;
    if (width == null && existing is Map) {
      final w = (existing['w'] as num?)?.toDouble();
      if (w != null && isValidNaturalWidth(w)) {
        width = w;
      }
    }
    final map = <String, dynamic>{
      'r': aspectRatio,
    };
    if (width != null && isValidNaturalWidth(width)) {
      map['w'] = width;
    }
    await _box.put(url, map);
    await _evictOldestIfNeeded();
  }

  static bool _unchanged(
    dynamic existing,
    double aspectRatio,
    double? naturalWidth,
  ) {
    if (existing is! Map) {
      return false;
    }
    final existingRatio = (existing['r'] as num?)?.toDouble();
    if (existingRatio == null ||
        !isValidAspectRatio(existingRatio) ||
        existingRatio != aspectRatio) {
      return false;
    }
    if (naturalWidth == null || !isValidNaturalWidth(naturalWidth)) {
      return true;
    }
    final existingWidth = (existing['w'] as num?)?.toDouble();
    return existingWidth != null &&
        isValidNaturalWidth(existingWidth) &&
        existingWidth == naturalWidth;
  }

  Future<void> _evictOldestIfNeeded() async {
    final overflow = _box.length - maxEntries;
    if (overflow > 0) {
      await _box.deleteAll(_box.keys.take(overflow));
    }
  }
}
