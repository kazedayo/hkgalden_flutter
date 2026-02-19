import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/app_shimmer.dart';
import 'package:hkgalden_flutter/ui/common/skeleton_block.dart';

class BlockedUsersLoadingSkeleton extends StatelessWidget {
  const BlockedUsersLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) => ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const SkeletonBlock(width: 50, height: 50),
            title: const SkeletonBlock(width: 75, height: 30, borderRadius: 10),
            trailing:
                const SkeletonBlock(width: 100, height: 30, borderRadius: 10),
          ),
        ),
      );
}
