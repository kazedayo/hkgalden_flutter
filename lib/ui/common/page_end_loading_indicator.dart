import 'package:flutter/material.dart';

class PageEndLoadingInidicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    child: Center(
      child: SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}