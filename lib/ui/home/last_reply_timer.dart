import 'package:flutter/material.dart';

class LastReplyTimer extends StatelessWidget {
  final DateTime time;

  const LastReplyTimer({super.key, required this.time});

  static String formatRelativeTime(DateTime timeObj) {
    final seconds = DateTime.now().difference(timeObj).inSeconds;
    if (seconds < 60) {
      return '${seconds < 0 ? 0 : seconds}s';
    }
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      return '${hours}h';
    }
    final days = hours ~/ 24;
    if (days < 30) {
      return '${days}d';
    }
    if (days < 365) {
      return '${days ~/ 30}mo';
    }
    return '${days ~/ 365}y';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatRelativeTime(time),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
