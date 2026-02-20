import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/app_shimmer.dart';
import 'package:hkgalden_flutter/ui/common/skeleton_block.dart';

class ListLoadingSkeletonCell extends StatelessWidget {
  final bool enabled;
  const ListLoadingSkeletonCell({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: AppShimmer(
          invert: true,
          enabled: enabled,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: SkeletonBlock(width: double.infinity, height: 30),
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: SkeletonBlock(width: double.infinity, height: 25),
                    ),
                  ),
                  const Spacer(),
                  const Chip(
                    label: Text('#哈哈'),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
      );
}
