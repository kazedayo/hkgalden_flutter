import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;

  const CustomAlertDialog(
      {Key key, @required this.title, @required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(color: Colors.black87),
        ),
        content: Text(
          content,
          style: TextStyle(color: Colors.black87),
        ),
        actions: <Widget>[
          FlatButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            highlightColor: Colors.grey[300],
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
}
