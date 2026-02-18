import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserThreadListLoadingSkeleton extends StatelessWidget {
  const UserThreadListLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Theme.of(context).scaffoldBackgroundColor,
        highlightColor: Theme.of(context).primaryColor,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 10,
          itemBuilder: (context, index) => ListTile(
            title: Container(
              height: 30,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100), color: Colors.grey),
            ),
            trailing: const Chip(label: Text('haha')),
          ),
        ),
      );
}
