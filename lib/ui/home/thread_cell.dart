import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThreadCell extends StatelessWidget {
  final String title;
  final String authorName;
  final int totalReplies;
  final DateTime lastReply;

  ThreadCell({
    this.title,
    this.authorName,
    this.totalReplies,
    this.lastReply,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.face, size: 15),
            SizedBox(width: 5),
            Text(authorName),
            SizedBox(width: 10),
            Icon(Icons.reply, size: 15),
            SizedBox(width: 5),
            Text(totalReplies.toString()),
            SizedBox(width: 10),
            Icon(Icons.access_time, size: 15),
            SizedBox(width: 5),
            Text(timeago.format(lastReply, locale: 'en_short')),
          ],
        ),
      ],
    ),
  );
}