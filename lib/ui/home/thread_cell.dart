import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/home/last_reply_timer.dart';

class ThreadCell extends StatelessWidget {
  final Thread thread;
  final Function onTap;
  final Function onLongPress;

  const ThreadCell(
      {Key key, this.onTap, this.onLongPress, @required this.thread})
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
                  Text(thread.title,
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
                          thread.replies[0].authorNickname,
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.reply, size: 13),
                        SizedBox(width: 5),
                        Text(
                          thread.totalReplies.toString(),
                          style: Theme.of(context).textTheme.caption,
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.access_time, size: 13),
                        SizedBox(width: 5),
                        LastReplyTimer(
                            key: ValueKey(thread.threadId),
                            time: thread.replies.length == 2
                                ? thread.replies[1].date.toLocal()
                                : thread.replies[0].date.toLocal()),
                        Spacer(),
                        Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text('#${thread.tagName}',
                              strutStyle: StrutStyle(height: 1.25),
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                          //labelPadding: EdgeInsets.zero,
                          backgroundColor: thread.tagColor,
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
          Divider(height: 1, thickness: 1),
        ],
      );
}
