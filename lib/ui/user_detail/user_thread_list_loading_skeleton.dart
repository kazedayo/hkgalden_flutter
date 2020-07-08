import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserThreadListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: 20,
          itemBuilder: (context, index) => Row(
                children: <Widget>[
                  Flexible(
                    flex: 4,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(12, 8, 0, 8),
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey),
                    ),
                  ),
                  Spacer(),
                  Flexible(
                    flex: 2,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 8, 12, 8),
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey),
                    ),
                  ),
                ],
              )),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).splashColor);
}
