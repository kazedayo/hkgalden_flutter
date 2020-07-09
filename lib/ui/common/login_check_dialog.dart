import 'package:flutter/material.dart';

class LoginCheckDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('未登入'),
        content: Text('請先登入'),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
}
