import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class BlockedUserCell extends StatefulWidget {
  final User user;

  BlockedUserCell({this.user});

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
  Widget build(BuildContext context) => FlatButton(
      onPressed: () {
        setState(() {
          _unblock = !_unblock;
        });
      },
      child: Text(widget.user.nickName,
          style: Theme.of(context).textTheme.bodyText1.copyWith(
              decoration:
                  _unblock ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2.5,
              decorationColor: Colors.white,
              color: widget.user.gender == 'M'
                  ? Theme.of(context).colorScheme.brotherColor
                  : Theme.of(context).colorScheme.sisterColor)));
}
