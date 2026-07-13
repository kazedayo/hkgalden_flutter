import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;

  final bool invert;

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
