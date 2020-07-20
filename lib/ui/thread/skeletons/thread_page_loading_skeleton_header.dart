import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ThreadPageLoadingSkeletonHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: Container(
        height: 50,
        child: Center(
          child: Container(
            height: 20,
            width: 50,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(5)),
          ),
        ),
      ),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
