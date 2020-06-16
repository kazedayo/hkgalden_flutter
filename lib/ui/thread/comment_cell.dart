import 'package:flutter/material.dart';

class CommentCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                child: Icon(Icons.account_circle, size: 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff7435a0),Color(0xff4a72d3)],
                  ),
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Text('username'),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Floor #'),
                  Text('Date'),
                ],
              ),
            ],
          ),
          Text('This is a comment.'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(icon: Icon(Icons.format_quote), onPressed: () => null),
              IconButton(icon: Icon(Icons.block), onPressed: () => null),
              IconButton(icon: Icon(Icons.flag), onPressed: () => null),
            ],
          ),
        ],
      ),
    ),
  );
}