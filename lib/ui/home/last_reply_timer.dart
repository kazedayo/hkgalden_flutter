import 'package:flutter/material.dart';

class LastReplyTimer extends StatelessWidget {
  final DateTime time;

  const LastReplyTimer({super.key, required this.time});

  static String formatRelativeTime(DateTime timeObj) {
    final now = DateTime.now();
    final difference = now.difference(timeObj);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inSeconds > 0 ? difference.inSeconds : 0}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatRelativeTime(time),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
