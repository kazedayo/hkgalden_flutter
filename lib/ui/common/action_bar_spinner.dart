import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';

class ActionBarSpinner extends StatelessWidget {
  final bool isVisible;

  const ActionBarSpinner({Key? key, required this.isVisible}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Visibility(
          visible: isVisible,
          child: const ProgressSpinner(),
        ),
      );
}
