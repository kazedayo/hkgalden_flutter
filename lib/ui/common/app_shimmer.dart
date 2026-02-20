import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps [child] in a [Shimmer.fromColors] using the app's theme colours.
///
/// Set [invert] to `true` to swap base and highlight colours (used in the
/// home-page thread-list skeleton, where the card background is lighter).
class AppShimmer extends StatelessWidget {
  final Widget child;

  /// When true, base = primaryColor and highlight = scaffoldBackgroundColor.
  /// When false (default), base = scaffoldBackgroundColor and highlight = primaryColor.
  final bool invert;

  /// Whether the shimmer animation is active.
  final bool enabled;

  const AppShimmer(
      {super.key,
      required this.child,
      this.invert = false,
      this.enabled = true});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        enabled: enabled,
        baseColor: invert
            ? Theme.of(context).primaryColor
            : Theme.of(context).scaffoldBackgroundColor,
        highlightColor: invert
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).primaryColor,
        child: child,
      );
}
