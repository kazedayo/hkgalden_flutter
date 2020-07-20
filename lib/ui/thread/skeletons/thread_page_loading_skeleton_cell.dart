import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ThreadPageLoadingSkeletonCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        height: 200,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 100,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 125,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(flex: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
            Spacer(flex: 2)
          ],
        ),
      ),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
