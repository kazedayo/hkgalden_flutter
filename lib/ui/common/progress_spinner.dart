import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProgressSpinner extends StatelessWidget {
  final double? value;
  final double size;

  const ProgressSpinner({super.key, this.value, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final Widget indicator =
        Theme.of(context).platform == TargetPlatform.iOS
            ? CupertinoActivityIndicator(radius: size / 2)
            : CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
              );

    // UnconstrainedBox: resist non-square tight constraints (e.g. OctoImage).
    return UnconstrainedBox(
      child: SizedBox.square(
        dimension: size,
        child: indicator,
      ),
    );
  }
}
