import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/app_shimmer.dart';
import 'package:hkgalden_flutter/ui/common/skeleton_block.dart';

class UserThreadListLoadingSkeleton extends StatelessWidget {
  const UserThreadListLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 10,
          itemBuilder: (context, index) => const ListTile(
            title: SkeletonBlock(width: double.infinity, height: 30),
            trailing: Chip(label: Text('haha')),
          ),
        ),
      );
}
