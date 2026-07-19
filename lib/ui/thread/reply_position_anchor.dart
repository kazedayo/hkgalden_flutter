import 'package:flutter/widgets.dart';

/// Tracks reply cell positions for reading-position persistence.
class ReplyAnchorRegistry {
  final Map<int, BuildContext> _byFloor = {};

  bool get hasEntries => _byFloor.isNotEmpty;

  void register(int floor, BuildContext context) {
    _byFloor[floor] = context;
  }

  void unregister(int floor, BuildContext context) {
    if (identical(_byFloor[floor], context)) {
      _byFloor.remove(floor);
    }
  }

  int? readingFloor({required double viewportTopY}) {
    int? bestFloor;
    var bestTop = double.negativeInfinity;
    int? nearestBelowFloor;
    var nearestBelowDist = double.infinity;

    for (final entry in _byFloor.entries) {
      final box = entry.value.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (top <= viewportTopY + 24) {
        if (top >= bestTop) {
          bestTop = top;
          bestFloor = entry.key;
        }
      } else if (bottom > viewportTopY) {
        final dist = top - viewportTopY;
        if (dist < nearestBelowDist) {
          nearestBelowDist = dist;
          nearestBelowFloor = entry.key;
        }
      }
    }
    return bestFloor ?? nearestBelowFloor;
  }

  int? lastVisibleFloor({
    required double viewportTopY,
    required double viewportBottomY,
  }) {
    int? bestFloor;
    for (final entry in _byFloor.entries) {
      final box = entry.value.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (bottom > viewportTopY && top < viewportBottomY) {
        if (bestFloor == null || entry.key > bestFloor) {
          bestFloor = entry.key;
        }
      }
    }
    return bestFloor;
  }
}

/// Registers [floor] geometry with [registry] while [child] is mounted.
class ReplyPositionAnchor extends StatefulWidget {
  final int floor;
  final ReplyAnchorRegistry registry;
  final Widget child;

  const ReplyPositionAnchor({
    super.key,
    required this.floor,
    required this.registry,
    required this.child,
  });

  @override
  State<ReplyPositionAnchor> createState() => _ReplyPositionAnchorState();
}

class _ReplyPositionAnchorState extends State<ReplyPositionAnchor> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.registry.register(widget.floor, context);
  }

  @override
  void didUpdateWidget(covariant ReplyPositionAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floor != widget.floor ||
        oldWidget.registry != widget.registry) {
      oldWidget.registry.unregister(oldWidget.floor, context);
      widget.registry.register(widget.floor, context);
    }
  }

  @override
  void dispose() {
    widget.registry.unregister(widget.floor, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
