import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BlockedUsersLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: 20,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 20,
              childAspectRatio: 4),
          itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              )),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).splashColor);
}
