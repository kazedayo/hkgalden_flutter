import 'package:flutter/material.dart';

Future<void> showCustomAlert({
  required BuildContext context,
  required String title,
  required String content,
}) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showLoginRequired(BuildContext context) {
  return showCustomAlert(context: context, title: '未登入', content: '請先登入');
}
