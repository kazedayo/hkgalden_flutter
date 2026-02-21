import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/icon_text_item.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isLocked = thread.status == 'locked';
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    final dividerColor = theme.dividerColor;
    final bodySmallStyle = textTheme.bodySmall;

    Widget cellContent = InkWell(
      onTap: () => onTap(),
      onLongPress: () => onLongPress(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    thread.title,
                    style: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isLocked
                            ? AppTheme.lockedColor
                            : AppTheme.activeColor),
                  ),
                ),
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.lock,
                      size: 15,
                      color: AppTheme.lockedColor,
                    ),
                  )
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconTextItem(
                  icon: Icons.face_rounded,
                  textStyle: bodySmallStyle,
                  text: thread.replies[0].authorNickname,
                ),
                const SizedBox(width: 10),
                IconTextItem(
                  icon: Icons.reply_rounded,
                  textStyle: bodySmallStyle,
                  text: thread.totalReplies.toString(),
                ),
                const SizedBox(width: 10),
                IconTextItem(
                  icon: Icons.access_time_rounded,
                  textStyle: bodySmallStyle,
                  text: LastReplyTimer.formatRelativeTime(
                    thread.replies.length == 2
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
    );

    if (isLocked) {
      return Ink(
        color: scaffoldBackgroundColor,
        child: cellContent,
      );
    }

    return cellContent;
  }
}
