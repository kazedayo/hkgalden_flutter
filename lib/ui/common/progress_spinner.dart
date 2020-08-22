import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProgressSpinner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoActivityIndicator(radius: 9);
        break;
      case TargetPlatform.android:
        return SizedBox.fromSize(
          size: Size.square(15),
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
        );
        break;
      default:
        return SizedBox.fromSize(
          size: Size.square(15),
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
        );
    }
  }
}
