import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProgressSpinner extends StatelessWidget {
  final double? value;

  const ProgressSpinner({Key? key, this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: const Size.square(15),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Theme.of(context).platform == TargetPlatform.iOS
            ? const CupertinoActivityIndicator()
            : CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey)),
      ),
    );
  }
}
