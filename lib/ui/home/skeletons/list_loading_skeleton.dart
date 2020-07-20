import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:shimmer/shimmer.dart';

class ListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(top: 10),
        child: Shimmer.fromColors(
            child: ListView(
                physics: NeverScrollableScrollPhysics(),
                children:
                    List.generate(50, (index) => ListLoadingSkeletonCell())),
            baseColor: Theme.of(context).primaryColor,
            highlightColor: Theme.of(context).scaffoldBackgroundColor),
      );
}
