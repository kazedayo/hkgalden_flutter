import 'package:flutter/material.dart';

class ProgressSpinner extends StatelessWidget {
  const ProgressSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnconstrainedBox(
      child: SizedBox.square(
        dimension: 15,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
        ),
      ),
    );
  }
}
