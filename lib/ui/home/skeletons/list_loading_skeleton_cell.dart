import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListLoadingSkeletonCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Shimmer.fromColors(
            child: Column(
              children: <Widget>[
                Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.grey,
                    ),
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    height: 30),
                Row(
                  children: <Widget>[
                    Flexible(
                      flex: 2,
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey,
                          ),
                          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          height: 25),
                    ),
                    Spacer(),
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Text('#哈哈'),
                      //labelPadding: EdgeInsets.zero,
                      backgroundColor: Colors.grey,
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ],
            ),
            baseColor: Theme.of(context).primaryColor,
            highlightColor: Theme.of(context).scaffoldBackgroundColor),
      );
}
