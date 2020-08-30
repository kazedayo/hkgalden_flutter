import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BlockedUsersLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
          ),
          title: Container(
            width: 75,
            height: 30,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.grey),
          ),
          trailing: Container(
            width: 100,
            height: 30,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.grey),
          ),
        ),
      ),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
