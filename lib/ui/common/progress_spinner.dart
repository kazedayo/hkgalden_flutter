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

    // Parents like OctoImage (via StackFit.passthrough) can apply tight
    // non-square constraints. SizedBox alone cannot resist those, so the
    // indicator would lay out as an ellipse. UnconstrainedBox lets the
    // spinner keep a fixed square size and stay centered in the space.
    return UnconstrainedBox(
      child: SizedBox.square(
        dimension: size,
        child: indicator,
      ),
    );
  }
}
