import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:shimmer/shimmer.dart';

class ListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).primaryColor,
          highlightColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              10,
              (index) => ListLoadingSkeletonCell(),
            ),
          ),
        ),
      );
}
