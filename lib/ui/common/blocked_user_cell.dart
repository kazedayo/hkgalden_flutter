import 'package:flutter/material.dart';

class BlockedUserCell extends StatefulWidget {
  final String userName;

  BlockedUserCell({this.userName});

  @override
  _BlockedUserCellState createState() => _BlockedUserCellState();
}

class _BlockedUserCellState extends State<BlockedUserCell> {
  bool _unblock;

  @override
  void initState() {
    _unblock = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        setState(() {
          _unblock = !_unblock;
        });
      },
      child: Center(
        child: Text(widget.userName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6.copyWith(
                decoration: _unblock ? TextDecoration.lineThrough : null,
                decorationThickness: 2)),
      ));
}
