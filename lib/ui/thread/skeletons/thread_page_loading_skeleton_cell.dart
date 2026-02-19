import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/app_shimmer.dart';
import 'package:hkgalden_flutter/ui/common/skeleton_block.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

class ThreadPageLoadingSkeletonCell extends StatelessWidget {
  const ThreadPageLoadingSkeletonCell({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        height: 200,
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SkeletonBlock(width: 45, height: 45, borderRadius: 100),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SkeletonBlock(width: 100, height: 20),
                    const SizedBox(height: 5),
                    const SkeletonBlock(width: 50, height: 20),
                  ],
                ),
                const Spacer(),
                const SkeletonBlock(width: 100, height: 20),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBlock(height: 25, width: displayWidth(context)),
                const SizedBox(height: 10),
                SkeletonBlock(
                  height: 25,
                  width: displayWidth(context) / 2,
                  borderRadius: 100,
                ),
              ],
            ),
            const Spacer(flex: 2)
          ],
        ),
      ));
}
