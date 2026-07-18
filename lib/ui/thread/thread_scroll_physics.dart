import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Whether thread list should use rubber-band bounce overscroll.
///
/// iOS / macOS get bounce; Android and others keep clamping so Material
/// stretch/glow can own the overscroll UX.
bool threadScrollBounceEnabled(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Asymmetric scroll physics for the thread page list.
///
/// - When [bounceEnabled] is false, both edges clamp (Android-style).
/// - When [bounceEnabled] is true and [clampLeading] is false, both edges
///   rubber-band (iOS-style).
/// - When [bounceEnabled] is true and [clampLeading] is true, the leading
///   edge clamps so previous-page pull can receive [OverscrollNotification],
///   while the trailing edge still bounces.
class ThreadScrollPhysics extends ScrollPhysics {
  const ThreadScrollPhysics({
    required this.clampLeading,
    this.bounceEnabled = true,
    super.parent,
  });

  /// When true, clamp the leading edge (underscroll / hit minScrollExtent)
  /// so previous-page pull receives OverscrollNotification like RefreshIndicator.
  final bool clampLeading;

  /// When true, allow rubber-band overscroll on edges that are not clamped.
  /// Set false on Android/Fuchsia/etc. so Material stretch/glow owns overscroll UX.
  final bool bounceEnabled;

  bool get _bounceLeading => bounceEnabled && !clampLeading;

  bool get _bounceTrailing => bounceEnabled;

  @override
  ThreadScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ThreadScrollPhysics(
      clampLeading: clampLeading,
      bounceEnabled: bounceEnabled,
      parent: buildParent(ancestor),
    );
  }

  /// Friction factor matching [BouncingScrollPhysics] (normal deceleration).
  double frictionFactor(double overscrollFraction) {
    return 0.52 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    // Zero out pasts on edges that must not bounce so friction only applies
    // to bouncing overscroll.
    final double overscrollPastStart = _bounceLeading
        ? math.max(position.minScrollExtent - position.pixels, 0.0)
        : 0.0;
    final double overscrollPastEnd = _bounceTrailing
        ? math.max(position.pixels - position.maxScrollExtent, 0.0)
        : 0.0;
    final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);

    if (overscrollPast == 0.0) {
      return offset;
    }

    final bool easing =
        (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor((overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    var total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(() {
      if (value == position.pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType.applyBoundaryConditions() was called redundantly.'),
          ErrorDescription(
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.',
          ),
          DiagnosticsProperty<ScrollPhysics>(
            'The physics object in question was',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
          DiagnosticsProperty<ScrollMetrics>(
            'The position object in question was',
            position,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());

    // Leading (toward minScrollExtent)
    if (!_bounceLeading) {
      if (value < position.pixels && position.pixels <= position.minScrollExtent) {
        // Underscroll.
        return value - position.pixels;
      }
      if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
        // Hit top edge.
        return value - position.minScrollExtent;
      }
    }

    // Trailing (toward maxScrollExtent)
    if (!_bounceTrailing) {
      if (position.maxScrollExtent <= position.pixels && position.pixels < value) {
        // Overscroll.
        return value - position.pixels;
      }
      if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) {
        // Hit bottom edge.
        return value - position.maxScrollExtent;
      }
    }

    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    if (!bounceEnabled) {
      // Identical to ClampingScrollPhysics.
      if (position.outOfRange) {
        double? end;
        if (position.pixels > position.maxScrollExtent) {
          end = position.maxScrollExtent;
        }
        if (position.pixels < position.minScrollExtent) {
          end = position.minScrollExtent;
        }
        assert(end != null);
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          end!,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }
      if (velocity.abs() < tolerance.velocity) {
        return null;
      }
      if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
        return null;
      }
      if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
        return null;
      }
      return ClampingScrollSimulation(
        position: position.pixels,
        velocity: velocity,
        tolerance: tolerance,
      );
    }

    // bounceEnabled == true
    if (position.outOfRange) {
      // If past min while clampLeading, snap back with clamping spring.
      if (clampLeading && position.pixels < position.minScrollExtent) {
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          position.minScrollExtent,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }
      // Otherwise bounce (past max, or past min when leading allowed).
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // Clamped leading: do not start a fling that only pushes further into the wall.
    if (clampLeading && velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    // iOS-style fling that may rubber-band at trailing (and leading if allowed).
    return BouncingScrollSimulation(
      spring: spring,
      position: position.pixels,
      velocity: velocity,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      tolerance: tolerance,
    );
  }

  @override
  double get minFlingVelocity =>
      bounceEnabled ? kMinFlingVelocity * 2.0 : super.minFlingVelocity;

  @override
  double carriedMomentum(double existingVelocity) {
    if (!bounceEnabled) {
      return super.carriedMomentum(existingVelocity);
    }
    // Match BouncingScrollPhysics momentum build-up.
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(), 40000.0);
  }

  @override
  double? get dragStartDistanceMotionThreshold =>
      bounceEnabled ? 3.5 : super.dragStartDistanceMotionThreshold;
}
