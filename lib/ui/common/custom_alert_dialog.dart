import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showCustomAlert({
  required BuildContext context,
  required String title,
  required String content,
  String okLabel = 'OK',
}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            okLabel,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    ),
  );
}
