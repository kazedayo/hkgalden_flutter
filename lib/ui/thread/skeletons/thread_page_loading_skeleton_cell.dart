import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/skeleton_block.dart';

class ThreadPageLoadingSkeletonCell extends StatelessWidget {
  const ThreadPageLoadingSkeletonCell({super.key});

  static const double totalHeight = 200;

  static const double _verticalMargin = 12;
  static const double _contentHeight = totalHeight - _verticalMargin * 2; // 176

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: _verticalMargin,
        ),
        height: _contentHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SkeletonBlock(
                          width: 45, height: 45, borderRadius: 100),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SkeletonBlock(width: 100, height: 20),
                          SizedBox(height: 5),
                          SkeletonBlock(width: 50, height: 20),
                        ],
                      ),
                      const Spacer(),
                      const SkeletonBlock(width: 100, height: 20),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SkeletonBlock(height: 25, width: width),
                      const SizedBox(height: 10),
                      SkeletonBlock(
                        height: 25,
                        width: width / 2,
                        borderRadius: 100,
                      ),
                    ],
                  ),
                ],
            );
          },
        ),
      );
}
