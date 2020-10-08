import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;

  const CustomAlertDialog(
      {Key key, @required this.title, @required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            )
          : AlertDialog(
              title: Text(
                title,
              ),
              content: Text(
                content,
              ),
              actions: <Widget>[
                FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  highlightColor: Colors.grey[800],
                  child: Text(
                    'OK',
                    style: TextStyle(color: Theme.of(context).accentColor),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
}

void showCustomDialog({BuildContext context, Function(BuildContext) builder}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? showCupertinoDialog(
            context: context,
            builder: builder,
          )
        : showModal(
            context: context,
            builder: builder,
          );
