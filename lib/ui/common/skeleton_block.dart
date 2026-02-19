import 'package:flutter/material.dart';

/// A grey rounded rectangle used as a placeholder inside shimmer skeletons.
class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 100,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
}
