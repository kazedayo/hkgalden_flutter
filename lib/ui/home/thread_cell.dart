import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/home/last_reply_timer.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class ThreadCell extends StatelessWidget {
  final Thread thread;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ThreadCell({
    super.key,
    required this.onTap,
    required this.onLongPress,
    required this.thread,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isLocked = thread.status == 'locked';
    final bodySmallStyle = textTheme.bodySmall;
    final metaColor = bodySmallStyle?.color;
    final titleStyle = textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w500,
      color: isLocked ? AppTheme.lockedColor : AppTheme.activeColor,
    );

    // Prefer the latest reply date when present (same rule as before).
    final lastReply = thread.replies.length == 2
        ? thread.replies[1]
        : thread.replies[0];
    final timeText =
        LastReplyTimer.formatRelativeTime(lastReply.date.toLocal());
    final authorNickname = thread.replies[0].authorNickname;
    final replyCount = thread.totalReplies.toString();

    // Single flattened metadata row (avoids 3 nested IconTextItem Rows).
    final metaRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Icon(Icons.face_rounded, size: 13, color: metaColor),
        const SizedBox(width: 5),
        Text(authorNickname, style: bodySmallStyle),
        const SizedBox(width: 10),
        Icon(Icons.reply_rounded, size: 13, color: metaColor),
        const SizedBox(width: 5),
        Text(replyCount, style: bodySmallStyle),
        const SizedBox(width: 10),
        Icon(Icons.access_time_rounded, size: 13, color: metaColor),
        const SizedBox(width: 5),
        Text(timeText, style: bodySmallStyle),
        const Spacer(),
        ThreadTagChip(
          label: thread.tagName,
          backgroundColor: thread.tagColor,
        ),
      ],
    );

    final cellContent = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      thread.title,
                      style: titleStyle,
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
                    ),
                ],
              ),
              const SizedBox(height: 10),
              metaRow,
            ],
          ),
        ),
      ),
    );

    if (isLocked) {
      return Ink(
        color: theme.scaffoldBackgroundColor,
        child: cellContent,
      );
    }

    return cellContent;
  }
}
