import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(top: 10),
        child: Shimmer.fromColors(
            child: ListView(
                physics: NeverScrollableScrollPhysics(),
                children: List.generate(
                    50,
                    (index) => Column(
                          children: <Widget>[
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.grey,
                                ),
                                margin: EdgeInsets.fromLTRB(10, 10, 10, 5),
                                height: 25),
                            Row(
                              children: <Widget>[
                                Flexible(
                                  flex: 2,
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.grey,
                                      ),
                                      margin:
                                          EdgeInsets.fromLTRB(10, 5, 10, 10),
                                      height: 20),
                                ),
                                Spacer()
                              ],
                            ),
                          ],
                        ))),
            baseColor: Theme.of(context).scaffoldBackgroundColor,
            highlightColor: Theme.of(context).splashColor),
      );
}
