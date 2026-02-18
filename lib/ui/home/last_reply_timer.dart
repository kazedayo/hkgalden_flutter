import 'dart:async';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';

class LastReplyTimer extends StatefulWidget {
  final DateTime time;

  const LastReplyTimer({super.key, required this.time});

  @override
  LastReplyTimerState createState() => LastReplyTimerState();
}

class LastReplyTimerState extends State<LastReplyTimer> {
  late Timer _timer;
  late String _time;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _time = DateTimeFormat.relative(widget.time, abbr: true);
      });
    });
    _time = DateTimeFormat.relative(widget.time, abbr: true);
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _time,
        style: Theme.of(context).textTheme.bodySmall,
      );
}
