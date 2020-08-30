import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:shimmer/shimmer.dart';

class ThreadPageLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              height: 50,
              child: Center(
                child: Container(
                  height: 20,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            );
          } else {
            return ThreadPageLoadingSkeletonCell();
          }
        },
      ),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
