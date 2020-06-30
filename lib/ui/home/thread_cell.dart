import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';

class ThreadCell extends StatelessWidget {
  final String title;
  final String authorName;
  final int totalReplies;
  final DateTime lastReply;
  final Function onTap;
  final Function onLongPress;

  ThreadCell({
    this.title,
    this.authorName,
    this.totalReplies,
    this.lastReply,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          InkWell(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title.trim(),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints.expand(height: 20),
                    child: Row(
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.face, size: 15),
                        SizedBox(width: 5),
                        Text(
                          authorName,
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.reply, size: 15),
                        SizedBox(width: 5),
                        Text(
                          totalReplies.toString(),
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.access_time, size: 15),
                        SizedBox(width: 5),
                        Text(
                          DateTimeFormat.relative(lastReply.toLocal(),
                              abbr: true),
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => onTap(),
            onLongPress: () => onLongPress(),
          ),
          Divider(indent: 8, height: 1, thickness: 1),
        ],
      );
}
