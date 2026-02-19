import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/icon_text_item.dart';
import 'package:hkgalden_flutter/ui/common/list_divider.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/home/last_reply_timer.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class ThreadCell extends StatelessWidget {
  final Thread thread;
  final Function onTap;
  final Function onLongPress;

  const ThreadCell(
      {super.key,
      required this.onTap,
      required this.onLongPress,
      required this.thread});

  @override
  Widget build(BuildContext context) => Material(
        color: thread.status == 'locked'
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).primaryColor,
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () => onTap(),
              onLongPress: () => onLongPress(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                        TextSpan(children: [
                          TextSpan(text: thread.title),
                          WidgetSpan(
                              child: thread.status == 'locked'
                                  ? const Icon(
                                      Icons.lock,
                                      size: 15,
                                      color: AppTheme.lockedColor,
                                    )
                                  : const SizedBox())
                        ]),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                fontWeight: FontWeight.w500,
                                color: thread.status == 'locked'
                                    ? AppTheme.lockedColor
                                    : AppTheme.activeColor)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        IconTextItem(
                          icon: Icons.face_rounded,
                          child: Text(
                            thread.replies[0].authorNickname,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconTextItem(
                          icon: Icons.reply_rounded,
                          child: Text(
                            thread.totalReplies.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconTextItem(
                          icon: Icons.access_time_rounded,
                          child: LastReplyTimer(
                            key: ValueKey(thread.threadId),
                            time: thread.replies.length == 2
                                ? thread.replies[1].date.toLocal()
                                : thread.replies[0].date.toLocal(),
                          ),
                        ),
                        const Spacer(),
                        ThreadTagChip(
                          label: thread.tagName,
                          backgroundColor: thread.tagColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const ListDivider(),
          ],
        ),
      );
}
