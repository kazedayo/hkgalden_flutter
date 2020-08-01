import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserThreadListLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      child: ListView.builder(
          padding: EdgeInsets.only(top: 12),
          physics: NeverScrollableScrollPhysics(),
          itemCount: 20,
          itemBuilder: (context, index) => Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(12, 8, 100, 8),
                      height: 35,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey),
                    ),
                  ),
                  Chip(
                    label: Text('#哈哈'),
                  ),
                  SizedBox(
                    width: 12,
                  )
                ],
              )),
      baseColor: Theme.of(context).scaffoldBackgroundColor,
      highlightColor: Theme.of(context).primaryColor);
}
