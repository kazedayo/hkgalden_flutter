import 'package:flutter/material.dart';

const Object kGaldenFabHeroTag = 'hkgalden_fab';

/// Keeps the FAB in place across routes and morphs its icon in flight.
Widget galdenFabHero({required Widget child}) {
  return Hero(
    tag: kGaldenFabHeroTag,
    flightShuttleBuilder: _galdenFabFlightShuttle,
    child: child,
  );
}

Widget _galdenFabFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromChild = (fromHeroContext.widget as Hero).child;
  final toChild = (toHeroContext.widget as Hero).child;
  final fromIcon =
      fromChild is FloatingActionButton ? fromChild.child : fromChild;
  final toIcon = toChild is FloatingActionButton ? toChild.child : toChild;

  if (fromIcon is Icon && toIcon is Icon && fromIcon.icon == toIcon.icon) {
    return toChild;
  }

  // Push drives 0→1; pop drives 1→0. Normalize so we always morph from→to.
  final progress = flightDirection == HeroFlightDirection.pop
      ? ReverseAnimation(animation)
      : animation;
  final outgoing = progress.drive(CurveTween(curve: Curves.easeIn));
  final incoming = progress.drive(CurveTween(curve: Curves.easeOut));

  return FloatingActionButton(
    heroTag: null,
    onPressed: () {},
    child: Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(outgoing),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 0.55).animate(outgoing),
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.125).animate(outgoing),
              child: fromIcon ?? const SizedBox.shrink(),
            ),
          ),
        ),
        FadeTransition(
          opacity: incoming,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.55, end: 1).animate(incoming),
            child: RotationTransition(
              turns: Tween<double>(begin: -0.125, end: 0).animate(incoming),
              child: toIcon ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    ),
  );
}
