import 'package:flutter/widgets.dart';

/// Remaps status-bar jumpTo(0) to minScrollExtent when content sits above center.
class ThreadPageScrollController extends ScrollController {
  ThreadPageScrollController({super.keepScrollOffset});

  bool holdCenterAtZero = false;

  double _resolveRequestedOffset(double offset) {
    if (offset != 0.0 || holdCenterAtZero || !hasClients) {
      return offset;
    }
    final position = this.position;
    if (!position.hasContentDimensions) {
      return offset;
    }
    final min = position.minScrollExtent;
    if (min < -0.5) {
      return min;
    }
    return offset;
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    return super.animateTo(
      _resolveRequestedOffset(offset),
      duration: duration,
      curve: curve,
    );
  }

  @override
  void jumpTo(double value) {
    super.jumpTo(_resolveRequestedOffset(value));
  }
}
