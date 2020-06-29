import 'package:flutter/material.dart';

class ActionBarSpinner extends StatelessWidget {
  final bool isVisible;

  const ActionBarSpinner({Key key, this.isVisible}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Visibility(
      visible: isVisible,
      child: CircularProgressIndicator(
        strokeWidth: 1,
      ),
    ),
  );
}
