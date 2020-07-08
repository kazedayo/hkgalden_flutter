import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';

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
