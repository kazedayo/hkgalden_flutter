import 'package:flutter/material.dart';

class ProgressSpinner extends StatelessWidget {
  final double? value;
  final double size;

  const ProgressSpinner({super.key, this.value, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator.adaptive(
          value: value,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
