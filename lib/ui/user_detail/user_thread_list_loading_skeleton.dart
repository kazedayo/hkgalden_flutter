import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:shimmer/shimmer.dart';

class UserThreadListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: 2,
          itemBuilder: (context, index) => ListLoadingSkeletonCell()),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
