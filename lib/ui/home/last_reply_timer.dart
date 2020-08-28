import 'dart:async';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';

class LastReplyTimer extends StatefulWidget {
  final DateTime time;

  const LastReplyTimer({Key key, @required this.time}) : super(key: key);

  @override
  _LastReplyTimerState createState() => _LastReplyTimerState();
}

class _LastReplyTimerState extends State<LastReplyTimer> {
  Timer _timer;
  String _time;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
        style: Theme.of(context).textTheme.caption,
        strutStyle: StrutStyle(height: 1.25),
      );
}
