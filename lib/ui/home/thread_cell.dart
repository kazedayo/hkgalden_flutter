import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/home/last_reply_timer.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class ThreadCell extends StatefulWidget {
  static const double padding = 8;
  static const double titleMetaGap = 10;
  static const double lockGap = 4;
  static const double lockSize = 15;
  static const double borderWidth = 1;
  static const double metaIconSize = 13;
  static const double chipVerticalPadding = 6;

  final Thread thread;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ThreadCell({
    super.key,
    required this.onTap,
    required this.onLongPress,
    required this.thread,
  });

  static TextStyle titleStyleFor(TextTheme textTheme, {required bool locked}) {
    return textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w500,
      color: locked ? AppTheme.lockedColor : AppTheme.activeColor,
    );
  }

  static TextStyle chipStyleFor(TextTheme textTheme, ColorScheme colors) {
    return textTheme.labelSmall!.copyWith(
      color: colors.onSecondary,
      fontWeight: FontWeight.w600,
    );
  }

  static double measureHeight({
    required BuildContext context,
    required Thread thread,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final inherited = DefaultTextStyle.of(context).style;
    final locked = thread.status == 'locked';
    final titleWidth = math.max(
      0.0,
      maxWidth -
          padding * 2 -
          (locked ? lockGap + lockSize : 0),
    );
    final titlePainter = TextPainter(
      text: TextSpan(
        text: thread.title,
        style: inherited.merge(titleStyleFor(theme.textTheme, locked: locked)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: titleWidth);
    final chipPainter = TextPainter(
      text: TextSpan(
        text: '#${thread.tagName}',
        style: inherited.merge(chipStyleFor(theme.textTheme, theme.colorScheme)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final metaHeight =
        math.max(metaIconSize, chipPainter.height + chipVerticalPadding * 2);
    final height =
        padding * 2 + titlePainter.height + titleMetaGap + metaHeight;
    titlePainter.dispose();
    chipPainter.dispose();
    return height;
  }

  @override
  State<ThreadCell> createState() => _ThreadCellState();
}

class _ThreadCellState extends State<ThreadCell> {
  Thread? _thread;
  Widget? _visual;
  String _semanticLabel = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visual = null;
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final sameThread = identical(_thread, thread) || _thread == thread;
    if (_visual == null || !sameThread) {
      _thread = thread;
      _visual = _buildVisual(context, thread);
    }

    return Semantics(
      button: true,
      label: _semanticLabel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: _visual,
        ),
      ),
    );
  }

  Widget _buildVisual(BuildContext context, Thread thread) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isLocked = thread.status == 'locked';
    final bodySmallStyle = textTheme.bodySmall;
    final metaColor = bodySmallStyle?.color;
    final titleStyle = ThreadCell.titleStyleFor(textTheme, locked: isLocked);

    final timeText = formatRelativeTime(
      thread.latestReply.date.toLocal(),
    );
    final authorNickname = thread.originalPost.authorNickname;
    final replyCount = thread.totalReplies.toString();
    _semanticLabel =
        '${thread.title}, $authorNickname, $replyCount, $timeText, ${thread.tagName}';

    final visual = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: ThreadCell.borderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ThreadCell.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    padding: EdgeInsets.only(left: ThreadCell.lockGap),
                    child: Icon(
                      Icons.lock,
                      size: ThreadCell.lockSize,
                      color: AppTheme.lockedColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ThreadCell.titleMetaGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.face_rounded,
                    size: ThreadCell.metaIconSize, color: metaColor),
                const SizedBox(width: 5),
                Text(authorNickname, style: bodySmallStyle),
                const SizedBox(width: 10),
                Icon(Icons.reply_rounded,
                    size: ThreadCell.metaIconSize, color: metaColor),
                const SizedBox(width: 5),
                Text(replyCount, style: bodySmallStyle),
                const SizedBox(width: 10),
                Icon(Icons.access_time_rounded,
                    size: ThreadCell.metaIconSize, color: metaColor),
                const SizedBox(width: 5),
                Text(timeText, style: bodySmallStyle),
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
        color: theme.scaffoldBackgroundColor,
        child: visual,
      );
    }
    return visual;
  }
}
