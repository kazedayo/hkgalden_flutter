import 'package:flutter/material.dart';

Future<void> showCustomAlert({
  required BuildContext context,
  required String title,
  required String content,
  String okLabel = 'OK',
}) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(okLabel),
        ),
      ],
    ),
  );
}
