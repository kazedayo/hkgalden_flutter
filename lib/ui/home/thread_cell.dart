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
  Widget build(BuildContext context) => Material(
        color: thread.status == 'locked'
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).primaryColor,
        child: Column(
          children: <Widget>[
            InkWell(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                        TextSpan(children: [
                          TextSpan(text: thread.title),
                          WidgetSpan(
                              child: thread.status == 'locked'
                                  ? Icon(
                                      Icons.lock,
                                      size: 15,
                                      color: Colors.grey,
                                    )
                                  : SizedBox())
                        ]),
                        style: Theme.of(context).textTheme.subtitle1.copyWith(
                            fontWeight: FontWeight.w500,
                            color: thread.status == 'locked'
                                ? Colors.grey
                                : Colors.white)),
                    SizedBox(height: 10),
                    Container(
                      //constraints: BoxConstraints.expand(height: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text.rich(
                            TextSpan(children: [
                              WidgetSpan(
                                  child: Icon(Icons.face, size: 13),
                                  alignment: PlaceholderAlignment.middle),
                              WidgetSpan(
                                  child: SizedBox(
                                width: 5,
                              )),
                              WidgetSpan(
                                child: Text(
                                  thread.replies[0].authorNickname,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              )
                            ]),
                          ),
                          SizedBox(width: 10),
                          Text.rich(
                            TextSpan(children: [
                              WidgetSpan(
                                  child: Icon(Icons.reply, size: 13),
                                  alignment: PlaceholderAlignment.middle),
                              WidgetSpan(
                                  child: SizedBox(
                                width: 5,
                              )),
                              WidgetSpan(
                                child: Text(thread.totalReplies.toString(),
                                    style: Theme.of(context).textTheme.caption),
                              )
                            ]),
                          ),
                          SizedBox(width: 10),
                          Text.rich(
                            TextSpan(children: [
                              WidgetSpan(
                                  child: Icon(Icons.access_time, size: 13),
                                  alignment: PlaceholderAlignment.middle),
                              WidgetSpan(
                                  child: SizedBox(
                                width: 5,
                              )),
                              WidgetSpan(
                                child: LastReplyTimer(
                                    key: ValueKey(thread.threadId),
                                    time: thread.replies.length == 2
                                        ? thread.replies[1].date.toLocal()
                                        : thread.replies[0].date.toLocal()),
                              )
                            ]),
                          ),
                          Spacer(),
                          Chip(
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            label: Text('#${thread.tagName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .overline
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
        ),
      );
}
