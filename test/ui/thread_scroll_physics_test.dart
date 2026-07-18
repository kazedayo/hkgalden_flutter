import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/thread_scroll_physics.dart';

void main() {
  ScrollMetrics metrics({
    double min = 0.0,
    double max = 1000.0,
    required double pixels,
    double viewport = 500.0,
  }) {
    return FixedScrollMetrics(
      minScrollExtent: min,
      maxScrollExtent: max,
      pixels: pixels,
      viewportDimension: viewport,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 3.0,
    );
  }

  group('applyBoundaryConditions', () {
    test('clampLeading true + bounce: clamps past min, allows past max', () {
      const physics = ThreadScrollPhysics(
        clampLeading: true,
        bounceEnabled: true,
      );

      // Hit top from inside.
      final atTop = metrics(pixels: 10.0);
      final leadingDelta = physics.applyBoundaryConditions(atTop, -20.0);
      expect(leadingDelta, isNonZero);
      expect(leadingDelta, -20.0); // value - minScrollExtent

      // Underscroll while already at/past min.
      final pastMin = metrics(pixels: 0.0);
      final underscroll = physics.applyBoundaryConditions(pastMin, -30.0);
      expect(underscroll, isNonZero);
      expect(underscroll, -30.0); // value - pixels

      // Past max allowed (bounce trailing).
      final atBottom = metrics(pixels: 990.0);
      expect(physics.applyBoundaryConditions(atBottom, 1020.0), 0.0);

      final pastMax = metrics(pixels: 1000.0);
      expect(physics.applyBoundaryConditions(pastMax, 1030.0), 0.0);
    });

    test('clampLeading false + bounce: both edges allow overscroll', () {
      const physics = ThreadScrollPhysics(
        clampLeading: false,
        bounceEnabled: true,
      );

      final atTop = metrics(pixels: 10.0);
      expect(physics.applyBoundaryConditions(atTop, -20.0), 0.0);

      final pastMin = metrics(pixels: 0.0);
      expect(physics.applyBoundaryConditions(pastMin, -30.0), 0.0);

      final atBottom = metrics(pixels: 990.0);
      expect(physics.applyBoundaryConditions(atBottom, 1020.0), 0.0);

      final pastMax = metrics(pixels: 1000.0);
      expect(physics.applyBoundaryConditions(pastMax, 1030.0), 0.0);
    });

    test('bounceEnabled false: both edges clamp', () {
      const physics = ThreadScrollPhysics(
        clampLeading: false,
        bounceEnabled: false,
      );

      final atTop = metrics(pixels: 10.0);
      expect(physics.applyBoundaryConditions(atTop, -20.0), isNonZero);

      final pastMin = metrics(pixels: 0.0);
      expect(physics.applyBoundaryConditions(pastMin, -30.0), isNonZero);

      final atBottom = metrics(pixels: 990.0);
      expect(physics.applyBoundaryConditions(atBottom, 1020.0), isNonZero);

      final pastMax = metrics(pixels: 1000.0);
      expect(physics.applyBoundaryConditions(pastMax, 1030.0), isNonZero);
    });
  });

  group('applyTo', () {
    test('preserves clampLeading and bounceEnabled', () {
      const physics = ThreadScrollPhysics(
        clampLeading: true,
        bounceEnabled: false,
      );

      final applied = physics.applyTo(const AlwaysScrollableScrollPhysics());
      expect(applied, isA<ThreadScrollPhysics>());
      expect(applied.clampLeading, isTrue);
      expect(applied.bounceEnabled, isFalse);
      expect(applied.parent, isA<AlwaysScrollableScrollPhysics>());
    });
  });

  group('createBallisticSimulation', () {
    test('near max with positive velocity + bounce is non-null', () {
      const physics = ThreadScrollPhysics(
        clampLeading: true,
        bounceEnabled: true,
      );

      final position = metrics(pixels: 980.0);
      final sim = physics.createBallisticSimulation(position, 2000.0);
      expect(sim, isNotNull);
      expect(sim, isA<BouncingScrollSimulation>());
    });

    test('at min with negative velocity + clampLeading returns null', () {
      const physics = ThreadScrollPhysics(
        clampLeading: true,
        bounceEnabled: true,
      );

      final position = metrics(pixels: 0.0);
      final sim = physics.createBallisticSimulation(position, -2000.0);
      expect(sim, isNull);
    });
  });

  group('threadScrollBounceEnabled', () {
    test('iOS and macOS true; android false', () {
      expect(threadScrollBounceEnabled(TargetPlatform.iOS), isTrue);
      expect(threadScrollBounceEnabled(TargetPlatform.macOS), isTrue);
      expect(threadScrollBounceEnabled(TargetPlatform.android), isFalse);
      expect(threadScrollBounceEnabled(TargetPlatform.linux), isFalse);
      expect(threadScrollBounceEnabled(TargetPlatform.windows), isFalse);
      expect(threadScrollBounceEnabled(TargetPlatform.fuchsia), isFalse);
    });
  });
}
