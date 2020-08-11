import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';

class ThreadCell extends StatelessWidget {
  final String title;
  final String authorName;
  final int totalReplies;
  final DateTime lastReply;
  final String tagName;
  final Color tagColor;
  final Function onTap;
  final Function onLongPress;

  const ThreadCell(
      {Key key,
      this.title,
      this.authorName,
      this.totalReplies,
      this.lastReply,
      this.tagName,
      this.tagColor,
      this.onTap,
      this.onLongPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          InkWell(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Container(
                    //constraints: BoxConstraints.expand(height: 20),
                    child: Row(
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.face, size: 13),
                        SizedBox(width: 5),
                        Text(
                          authorName,
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.reply, size: 13),
                        SizedBox(width: 5),
                        Text(
                          totalReplies.toString(),
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.access_time, size: 13),
                        SizedBox(width: 5),
                        Text(
                          DateTimeFormat.relative(lastReply.toLocal(),
                              abbr: true),
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        Spacer(),
                        Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text('#$tagName',
                              strutStyle: StrutStyle(height: 1.25),
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                          //labelPadding: EdgeInsets.zero,
                          backgroundColor: tagColor,
                        )
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
