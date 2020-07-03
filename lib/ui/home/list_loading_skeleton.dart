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
                    (index) => ListTile(
                          title: Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              color: Colors.grey,
                              height: 25),
                          subtitle: Row(
                            children: <Widget>[
                              Flexible(
                                flex: 2,
                                child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    color: Colors.grey[900],
                                    height: 20),
                              ),
                              Spacer()
                            ],
                          ),
                        ))),
            baseColor: Theme.of(context).scaffoldBackgroundColor,
            highlightColor: Theme.of(context).splashColor),
      );
}
